package Hamster;

use strict;
use warnings;

use Mouse;

use AnyEvent;
use AnyEvent::DBI;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::IM::Connection;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::IM::Roster;

use Hamster::Localizator;

use Hamster::Human;
use Hamster::Dispatcher;

use Hamster::Command::Help;
use Hamster::Command::Ping;
use Hamster::Command::Nick;
use Hamster::Command::CreateReply;
use Hamster::Command::CreateTopic;
use Hamster::Command::ViewTopic;
use Hamster::Command::Subscribe;
use Hamster::Command::Stat;
use Hamster::Command::Lang;

has cv => (
    is => 'rw'
);

has dbh => (
    is => 'rw'
);

has connection_args => (
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { { resource => 'Hamster' } }
);

has localizator => (
    is      => 'rw',
    default => sub { Hamster::Localizator->new }
);

has jid => (
    isa => 'Str',
    is  => 'rw'
);

has password => (
    isa => 'Str',
    is  => 'rw'
);

has host => (
    isa => 'Str',
    is  => 'rw'
);

has port => (
    isa => 'Str',
    is  => 'rw'
);

has dispatcher => (
    is      => 'rw',
    default => sub {
        Hamster::Dispatcher->new(
            map => [
                qr/^HELP$/ => Hamster::Command::Help->new,
                qr/^PING$/ => Hamster::Command::Ping->new,
                qr/^STAT$/ => Hamster::Command::Stat->new,
                qr/^LANG$/ => Hamster::Command::Lang->new,
                qr/^NICK(?: ([a-zA-Z][a-zA-Z0-9-]{1,15}))?$/ =>
                  Hamster::Command::Nick->new,
                qr/^#(\d+)(\+)?$/ => Hamster::Command::ViewTopic->new,
                qr/^#(\d+)(?:\/(\d+))?\s+(.+)/ =>
                  Hamster::Command::CreateReply->new,
                '*' => Hamster::Command::CreateTopic->new
            ]
        );
    }
);

has client => (
    is      => 'rw',
    default => sub {
        AnyEvent::XMPP::Client->new(debug => $ENV{HAMSTER_DEBUG} ? 1 : 0);
    }
);

has roster => (
    is      => 'rw',
    default => sub { AnyEvent::XMPP::IM::Roster->new }
);

sub BUILD {
    my $self = shift;

    $self->dbh(AnyEvent::DBI->new("DBI:SQLite:dbname=test.db", "", ""));
    $self->dbh->attr('RaiseError', [0], sub { my ($dbh) = @_; $self->dbh($dbh)});
    
    $self->dispatcher->hamster($self);

    my $client = $self->client;

    $client->set_presence(undef, 'Hamster', 1);

    $client->add_account($self->jid, $self->password, $self->host,
        $self->port, $self->connection_args);

    $client->reg_cb(
        session_ready => sub {
            my ($client, $acc) = @_;

            warn 'connected!';
        },
        roster_update => sub {
            my ($client, $acc, $roster, $contacts) = @_;

            $self->roster($roster);

            $roster->debug_dump;
        },
        message => sub {
            my ($client, $acc, $msg) = @_;

            my ($jid, $resource) = split('/', $msg->from);

            $self->dbh->exec(
                qq/SELECT human.id,human.nick
                    FROM `human`
                    JOIN `jid` ON `human`.`id` = `human_id` WHERE `jid`=?/,
                $jid,
                sub {
                    my ($dbh, $rows, $rv) = @_;

                    if (@$rows) {
                        my $human_row = $rows->[0];

                        warn 'FOUND USER: ' . $human_row->[0];

                        my $human = Hamster::Human->new(
                            id       => $human_row->[0],
                            resource => $resource
                        );

                        $human->nick($human_row->[1]) if $human_row->[1];

                        return $self->dbh->exec(
                            qq/SELECT * FROM `jid` WHERE `human_id`=?/,
                            $human->id,
                            sub {
                                my ($dbh, $rows, $rv) = @_;

                                foreach my $jid (@$rows) {
                                    $human->add_jid($jid->[0], $jid->[2]);
                                }

                                use Data::Dumper;
                                warn Dumper $human;

                                return $self->dispatch($human, $msg, sub { });
                            }
                        );
                    }

                    warn 'USER NOT FOUND';

                    $self->dbh->exec(
                        'INSERT INTO `human` (`addtime`) VALUES (?)',
                        time,
                        sub {
                            my ($rs, $rows, $rv) = @_;

                            $dbh->func(
                                q/undef, undef, 'human', 'id'/,
                                'last_insert_id',
                                sub {
                                    my ($dbh, $result, $handle_error) = @_;

                                    $self->dbh->exec(
                                        'INSERT INTO `jid` (`human_id`,`jid`) VALUES (?, ?)',
                                        ($result, $jid) => sub {

                                            $dbh->func(
                                                q/undef, undef, 'jid', 'id'/,
                                                'last_insert_id',
                                                sub {
                                                    my ($dbh, $result, $handle_error) = @_;

                                                    my $human = Hamster::Human->new(
                                                        id       => $result,
                                                        resource => $resource
                                                    );

                                                    $human->add_jid($result, $jid);

                                                    use Data::Dumper;
                                                    warn Dumper $human;

                                                    return $self->dispatch($human,
                                                        $msg, sub { });
                                                }
                                            );
                                        }
                                    );
                                }
                            );
                        }
                    );
                }
            );
        },
        contact_request_subscribe => sub {
            my ($cl, $acc, $roster, $contact) = @_;

            $contact->send_subscribed;

            $contact->send_subscribe;

            warn "Subscribed to " . $contact->jid . "\n";
        },
        contact_subscribed => sub {
            my ($cl, $acc, $roster, $contact) = @_;

            $self->roster->add_contact($contact->jid, sub {});
        },
        contact_did_unsubscribe => sub {
            my ($cl, $acc, $roster, $contact) = @_;

            $contact->send_unsubscribe;

            $self->roster->delete_contact($contact->jid, sub {});
        },
        contact_unsubscribed => sub {
            my ($cl, $acc, $roster, $contact) = @_;

            $contact->send_unsubscribed;
        },
        error => sub {
            my ($client, $acc, $error) = @_;

            warn "error: " . $error->string;

            $self->cv->broadcast;
        },
        disconnect => sub {
            warn "Got disconnected";

            $self->cv->broadcast;
        },
    );
}

sub connect {
    my $self = shift;

    $self->cv(AnyEvent->condvar);

    $self->client->start;

    $self->cv->wait;
}

sub dispatch {
    my $self = shift;
    my ($human, $msg, $cb) = @_;

    $self->dispatcher->dispatch($human, $msg, sub { return $cb->(); });
}

sub disconnect {
    my $self = shift;

    $self->client->disconnect;
}

sub log {
    my $self = shift;
    my $message = shift;

    open FILE, ">> log.txt";
    print FILE $message;
    close FILE;
}

1;

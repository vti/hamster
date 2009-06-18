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
use Hamster::Command::List;
use Hamster::Command::Ping;
use Hamster::Command::Nick;
use Hamster::Command::CreateReply;
use Hamster::Command::CreateTopic;
use Hamster::Command::ViewTopic;
use Hamster::Command::Subscribe;
use Hamster::Command::Unsubscribe;
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
                qr/^HELP$/                   => Hamster::Command::Help->new,
                qr/^PING$/                   => Hamster::Command::Ping->new,
                qr/^(#)$/                    => Hamster::Command::List->new,
                qr/^STAT$/                   => Hamster::Command::Stat->new,
                qr/^LANG(?: ([a-z][a-z]))?$/ => Hamster::Command::Lang->new,
                qr/^NICK(?: ([a-zA-Z][a-zA-Z0-9-]{1,15}))?$/ =>
                  Hamster::Command::Nick->new,
                qr/^#(\d+)(\+)?$/ => Hamster::Command::ViewTopic->new,
                qr/^#(\d+)(?:\/(\d+))?\s+(.+)/ =>
                  Hamster::Command::CreateReply->new,
                qr/^S(?: (#)(\d+))?$/ => Hamster::Command::Subscribe->new,
                qr/^U (#)(\d+)$/      => Hamster::Command::Unsubscribe->new,
                '*'                   => Hamster::Command::CreateTopic->new
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
    $self->dbh->attr('unicode', [1], sub {});
    
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

            Hamster::Human->find(
                $self->dbh,
                {jid => $jid, resource => $resource} => sub {
                    my ($dbh, $human) = @_;

                    if ($human) {
                        $self->dispatch($human, $msg, sub { });
                    }
                    else {
                        Hamster::Human->create(
                            $dbh,
                            {jid => $jid, resource => $resource} => sub {
                                my ($dbh, $human) = @_;

                                $self->dispatch($human, $msg, sub { });
                            }
                        );
                    }
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

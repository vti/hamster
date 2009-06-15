package Hamster;

use strict;
use warnings;

use Mouse;

use AnyEvent;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::IM::Connection;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::IM::Roster;

use Hamster::Brain;
use Hamster::Localizator;

use Hamster::Human;
use Hamster::Dispatcher;

use Hamster::Command::Ping;
use Hamster::Command::Create;
use Hamster::Command::Stat;
use Hamster::Command::Lang;

has cv => (
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
                qr/^PING$/ => Hamster::Command::Ping->new,
                qr/^STAT$/ => Hamster::Command::Stat->new,
                qr/^LANG$/ => Hamster::Command::Lang->new,
                '*'        => Hamster::Command::Create->new
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

            $self->dispatcher->dispatch(
                $msg,
                sub {
                    my $answer = shift;

                    if ($answer) {
                        my $reply = $msg->make_reply;

                        $reply->add_body($answer->body);

                        $reply->send;
                    }

                    return;
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

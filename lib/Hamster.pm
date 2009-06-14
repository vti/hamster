package Hamster;

use Mouse;
use Encode;
use AnyEvent::XMPP::IM::Connection;
use AnyEvent::XMPP::IM::Message;

use Hamster::Localizator;

use Hamster::Human;
use Hamster::Dispatcher;

use Hamster::Command::Ping;
use Hamster::Command::Post;
use Hamster::Command::Stat;
use Hamster::Command::Lang;

has resource => (
    is      => 'Str',
    is      => 'rw',
    default => 'Hamster bot'
);

has localizator => (
    is      => 'rw',
    default => sub { Hamster::Localizator->new }
);

has username => (
    isa => 'Str',
    is  => 'rw'
);

has password => (
    isa => 'Str',
    is  => 'rw'
);

has domain => (
    isa => 'Str',
    is  => 'rw'
);

has dispatcher => (
    is      => 'rw',
    default => sub {
        Hamster::Dispatcher->new(
            map => [
                PING => Hamster::Command::Ping->new,
                STAT => Hamster::Command::Stat->new,
                LANG => Hamster::Command::Lang->new,
                _    => Hamster::Command::Post->new
            ]
        );
    }
);

has con => (is => 'rw');

has roster => (is => 'rw');

has debug => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0
);

sub BUILD {
    my $self = shift;

    my $con = AnyEvent::XMPP::IM::Connection->new(
        username => $self->username,
        password => $self->password,
        domain   => $self->domain,
        resource => $self->resource
    );

    $con->reg_cb(
        session_ready => sub { shift; $self->_on_online(@_) },
        roster_update => sub { shift; $self->_on_roster_update(@_) },
        disconnect    => sub { shift; $self->_on_offline(@_) },
        message_xml   => sub { shift; $self->_on_message(@_) },
        contact_request_subscribe =>
          sub { shift; $self->_on_subscribe_request(@_); },
        contact_subscribed   => sub { shift; $self->_on_subscribe(@_) },
        contact_unsubscribed => sub { shift; $self->_on_unsubscribe(@_) }
    );

    $con->reg_cb(
        debug_recv => sub {
            require XML::Twig;
            my $t = XML::Twig->new();
            $t->parse($_[1]);
            print "<--------------\n";
            $t->set_pretty_print('indented');
            $t->print;
            print "\n";
        },
        debug_send => sub {
            require XML::Twig;
            my $t = XML::Twig->new();
            $t->parse($_[1]);
            print "-------------->\n";
            $t->set_pretty_print('indented');
            $t->print;
            print "\n";
        },
    ) if $self->debug;

    $self->con($con);
}

sub connect {
    my $self = shift;

    my $connected;
    do {
        print STDERR "Connecting...\n";
        $connected = $self->con->connect;
    } while (!$connected && $self->con->may_try_connect);

    die "Could not connect to server: $!, " if !$connected;

    print STDERR "Connected!\n";
}

sub start {
    my $self = shift;

    $self->connect;
    AnyEvent->condvar->wait;
}

sub disconnect {
    my $self = shift;
}

sub _on_roster_update {
    my $self = shift;
    my ($roster, $contacts) = @_;

    $self->roster($roster);
}

sub _on_subscribe_request {
    my $self = shift;
    my ($roster, $contact, $message) = @_;

    $contact->send_subscribed;

    $contact->send_subscribe;
}

sub _on_subscribe {
    my $self = shift;
    my ($roster, $contact, $message) = @_;

}

sub _on_unsubscribe {
    my $self = shift;
    my ($roster, $contact, $message) = @_;

    $contact->send_unsubscribed;

    $contact->send_unsubscribe;

    $self->roster->delete_contact($contact->jid, sub {});
}

sub _on_online {
    my $self = shift;

    my $con = $self->con;

    $con->send_presence(
        undef, undef,
        status   => 'Bot',
        priority => -1,
    );
}

sub _on_offline {
    my $self = shift;
}

sub _on_message {
    my $self = shift;
    my ($node) = @_;

    return unless $node;

    my $from    = $node->attr('from');
    my @nodes   = grep { $_->name eq 'body' } $node->nodes;
    my $message = $nodes[0]->text;

    my ($jid, $resource) = split('/', $from);

    my $human = Hamster::Human->new(jid => $jid, resource => $resource);

    #if (time - $user->column('lastaction') < 5) {
    #my $msg = AnyEvent::XMPP::IM::Message->new(
    #to   => $from,
    #body => 'Вы слишком быстры!'
    #);
    #$msg->send($self->con);
    #return;
    #}

    if (my $msg = $self->dispatcher->dispatch($self, $human, $message)) {
        $msg->send($self->con);
    }
}

1;

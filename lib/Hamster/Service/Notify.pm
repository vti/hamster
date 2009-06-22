package Hamster::Service::Notify;

use Mouse;

extends 'Hamster::Service::Base';

use AnyEvent::XMPP::IM::Message;

sub run {
    my $self = shift;
    my ($body, $humans, $cb) = @_;

    my $hamster = $self->hamster;
    my $account = $hamster->client->get_account($hamster->jid);

    foreach my $human (@$humans) {
        $self->hook(
            notify => sub {
                my ($ctl, $args) = @_;

                my $msg = AnyEvent::XMPP::IM::Message->new(
                    to   => $human->jids->[0]->jid,
                    from => $hamster->jid,
                    body => $body->($human)
                );

                $msg->send($account->connection);

                $ctl->next;
            }
        );
    }

    return $self->call('notify', [], sub { $cb->() });
}

1;

package Hamster::Command::Lang;

use Mouse;
use AnyEvent::XMPP::IM::Message;

sub run {
    my $self = shift;
    my ($hamster, $human, $message) = @_;

    return AnyEvent::XMPP::IM::Message->new(
        to   => $human->jid,
        body => $hamster->localizator->language
    );
}

1;

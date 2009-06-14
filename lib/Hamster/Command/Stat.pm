package Hamster::Command::Stat;

use Mouse;
use AnyEvent::XMPP::IM::Message;

sub run {
    my $self = shift;
    my ($hamster, $human, $message) = @_;

    my $contacts = $hamster->roster->get_contacts;

    my $users = @$contacts;
    my $online = grep {
        $_->subscription ne 'none'
          && ($_->get_presence && !$_->get_presence->show)
    } @$contacts;

    my $stat = <<"";
Users : $users
Online: $online

    return AnyEvent::XMPP::IM::Message->new(
        to   => $human->jid,
        body => $stat
    );
}

1;

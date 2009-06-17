package Hamster::Command::Stat;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($human, $msg, $cb) = @_;

    my @contacts = $self->hamster->roster->get_contacts;

    my $users = @contacts;

    my $stat = <<"";
Users : $users

    my $reply = $msg->make_reply;

    $reply->add_body($stat);

    $reply->send;

    return $cb->();
}

1;

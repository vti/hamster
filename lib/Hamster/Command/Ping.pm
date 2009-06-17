package Hamster::Command::Ping;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($human, $msg, $cb) = @_;

    my $reply = $msg->make_reply;

    $reply->add_body('PONG');

    $reply->send;

    return $cb->();
}

1;

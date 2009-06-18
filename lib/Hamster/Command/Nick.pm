package Hamster::Command::Nick;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    my $reply = $self->msg->make_reply;

    $reply->add_body('PONG');

    $reply->send;

    return $cb->();
}

1;

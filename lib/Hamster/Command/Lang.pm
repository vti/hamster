package Hamster::Command::Lang;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    my $reply = $self->msg->make_reply;

    $reply->add_body($self->hamster->localizator->language);

    $reply->send;

    return $cb->();
}

1;

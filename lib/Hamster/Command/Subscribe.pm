package Hamster::Command::Subscribe;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    my $body = $self->msg->any_body;
    $body =~ s/^S //;

    return $cb->();
}

1;

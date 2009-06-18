package Hamster::Command::Ping;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    return $self->send('PONG', sub { $cb->() });
}

1;

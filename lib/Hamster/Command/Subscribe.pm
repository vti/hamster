package Hamster::Command::Subscribe;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($human, $msg, $cb) = @_;

    my $body = $msg->any_body;
    $body =~ s/^S //;

    return $cb->();
}

1;

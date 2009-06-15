package Hamster::Command::Ping;

use strict;
use warnings;

use base 'Hamster::Command::Base';

use Hamster::Answer;

sub run {
    my $self = shift;
    my ($message, $cb) = @_;

    $cb->(Hamster::Answer->new(body => 'PONG'));
}

1;

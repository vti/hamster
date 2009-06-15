package Hamster::Dispatcher;

use strict;
use warnings;

use Mouse;

has map => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] }
);

has hamster => (
    is  => 'rw',
    isa => 'Hamster'
);

sub add_map {
    my $self = shift;

    push @{$self->map}, @_;
}

sub dispatch {
    my $self = shift;
    my ($message, $cb) = @_;

    return $cb->() unless $message;

    my $command;
    my $default;

    for (my $i = 0; $i < @{$self->map}; $i += 2) {
        my $key     = $self->map->[$i];
        my $handler = $self->map->[$i + 1];

        if ($key eq '*') {
            $default = $handler;
            next;
        }

        if ($message =~ m/$key/) {
            $command = $handler;
            last;
        }
    }

    $command ||= $default;

    if ($command) {
        $command->hamster($self->hamster) unless $command->hamster;
        return $command->run($message, sub { return $cb->(shift) });
    }

    return $cb->();
}

1;

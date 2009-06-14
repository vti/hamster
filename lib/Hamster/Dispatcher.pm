package Hamster::Dispatcher;

use Mouse;

has map => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] }
);

sub add_map {
    my $self = shift;

    push @{$self->map}, @_;
}

sub dispatch {
    my $self = shift;
    my ($hamster, $human, $message) = @_;

    return unless $message;

    my $command;

    for (my $i = 0; $i < @{$self->map}; $i += 2) {
        my $key     = $self->map->[$i];
        my $handler = $self->map->[$i + 1];

        $command = $handler if $key eq '_';

        if ($message =~ s/^$key\s*//) {
            $command = $handler;
            last;
        }
    }

    return $command->run($hamster, $human, $message) if $command;

    return undef;
}

1;

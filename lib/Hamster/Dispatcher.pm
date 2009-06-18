package Hamster::Dispatcher;

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
    my ($human, $msg, $cb) = @_;

    return $cb->() unless $msg;

    my $command;
    my $default;

    my $body = $msg->any_body;

    $body =~ s/^\s+//;
    $body =~ s/\s+$//;

    my @args;
    for (my $i = 0; $i < @{$self->map}; $i += 2) {
        my $key     = $self->map->[$i];
        my $handler = $self->map->[$i + 1];

        if ($key eq '*') {
            push @args, $body;
            $default = $handler;
            next;
        }

        if ($body =~ s/$key//) {
            for ($1, $2, $3, $4, $5) {
                push @args, $_;
            }

            $command = $handler;
            last;
        }
    }

    $command ||= $default;

    if ($command) {
        $command->hamster($self->hamster) unless $command->hamster;
        $command->human($human);
        $command->msg($msg);
        $command->args([@args]) if @args;
        return $command->run(sub { return $cb->(shift) });
    }

    return $cb->();
}

1;

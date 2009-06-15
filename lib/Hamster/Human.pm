package Hamster::Human;

use Mouse;

has jid => (
    isa     => 'Str',
    is      => 'rw',
    default => ''
);

has resource => (
    isa     => 'Str',
    is      => 'rw',
    default => ''
);

use overload '""' => sub { shift->to_string }, fallback => 1;

sub parse {
    my $self   = shift;
    my $string = shift;

    return unless $string;

    my ($jid, $resource) = split('/', $string);

    $self->jid($jid) if $jid;
    $self->resource($resource) if $resource;

    return $self;
}

sub to_string {
    my $self = shift;

    if ($self->jid && $self->resource) {
        return join('/', $self->jid, $self->resource);
    }

    return $self->jid;
}

1;

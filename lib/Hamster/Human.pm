package Hamster::Human;

use Mouse;

use Hamster::Human::JID;

has id => (
    isa => 'Int',
    is  => 'rw'
);

has nick => (
    isa => 'Str',
    is  => 'rw'
);

has jids => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] }
);

has resource => (
    isa => 'Str',
    is  => 'rw'
);

has lang => (
    isa     => 'Str',
    is      => 'rw',
    default => 'en'
);

sub jid {
    my $self = shift;

    if (@_) {
        my $from = $_[0];
        my ($jid) = split('/', $from);

        my @jids = grep { $_->jid eq $jid } @{$self->jids};
        return $jids[0];
    }
}

sub add_jid {
    my $self = shift;

    if (@_) {
        push @{$self->jids},
          Hamster::Human::JID->new(id => $_[0], jid => $_[1]);
    }
}

1;

package Hamster::Command::Base;

use Mouse;

has hamster => (
    is  => 'rw',
    isa => 'Hamster'
);

has args => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] }
);

has human => (
    isa => 'Hamster::Human',
    is  => 'rw'
);

has msg => (
    isa => 'AnyEvent::XMPP::IM::Message',
    is  => 'rw'
);

1;

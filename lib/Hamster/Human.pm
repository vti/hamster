package Hamster::Human;

use Mouse;

has jid => (
    isa => 'Str',
    is  => 'rw'
);

has resource => (
    isa => 'Str',
    is  => 'rw'
);

1;

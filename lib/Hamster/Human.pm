package Hamster::Human;

use Mouse;

has id => (
    isa => 'Int',
    is  => 'rw'
);

has resource => (
    isa => 'Str',
    is  => 'rw'
);

1;

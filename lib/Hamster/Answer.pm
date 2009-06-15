package Hamster::Answer;

use Mouse;

has to => (
    isa => 'Str',
    is  => 'rw'
);

has body => (
    isa => 'Str',
    is  => 'rw'
);

1;

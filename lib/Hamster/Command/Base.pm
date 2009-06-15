package Hamster::Command::Base;

use Mouse;

has hamster => (
    is  => 'rw',
    isa => 'Hamster'
);

1;

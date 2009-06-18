package Hamster::Human::JID;

use Mouse;

has id => (
    isa => 'Int',
    is  => 'rw'
);

has jid => (
    isa => 'Str',
    is  => 'rw'
);

1;

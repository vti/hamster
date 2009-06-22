package Hamster::Service::Base;

use Mouse;

use Async::Hooks;

has hamster => (
    is => 'rw'
);

has hooks => (
    isa     => 'Async::Hooks',
    is      => 'rw',
    default => sub { Async::Hooks->new },
    handles => [qw( hook call )]
);

1;

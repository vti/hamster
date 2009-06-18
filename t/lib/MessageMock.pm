package MessageMock;

use strict;
use warnings;

use base 'Test::MockObject';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->mock(
        make_reply => sub {
            $self->mock(add_body =>
                  sub { shift; $self->set_always(any_body => shift) });

            return $self;
        }
    );

    $self->mock(send => sub {})
}

1;

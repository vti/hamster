package Hamster::Command::Lang;

use base 'Hamster::Command::Base';

use Hamster::Answer;

sub run {
    my $self = shift;
    my ($message, $cb) = @_;

    $cb->(Hamster::Answer->new(body => $self->hamster->localizator->language));
}

1;

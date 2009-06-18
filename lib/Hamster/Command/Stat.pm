package Hamster::Command::Stat;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    my @contacts = $self->hamster->roster->get_contacts;

    my $users = @contacts;

    my $stat = <<"";
Users : $users

    return $self->send($stat, sub { $cb->() });
}

1;

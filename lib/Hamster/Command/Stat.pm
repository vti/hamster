package Hamster::Command::Stat;

use base 'Hamster::Command::Base';

use Hamster::Answer;

sub run {
    my $self = shift;
    my ($message, $cb) = @_;

    my $contacts = $self->hamster->roster->get_contacts;

    my $users = @$contacts;

    my $stat = <<"";
Users : $users

    return $cb->(Hamster::Answer->new(body => $stat));
}

1;

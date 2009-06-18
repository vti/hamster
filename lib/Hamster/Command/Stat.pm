package Hamster::Command::Stat;

use Mouse;

extends 'Hamster::Command::Base';

use Hamster::Human;

sub run {
    my $self = shift;
    my ($cb) = @_;

    my @contacts = $self->hamster->roster->get_contacts;

    Hamster::Human->count_all(
        $self->hamster->dbh,
        {},
        sub {
            my ($dbh, $total) = @_;

            my $active = @contacts;
            my $online =
              grep { my $p = $_->get_presence; $p && !$p->show } @contacts;

            my $stat = $self->render(stat => ($total, $active, $online));

            return $self->send($stat, sub { $cb->() });
        }
    );
}

1;

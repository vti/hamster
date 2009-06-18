package Hamster::Subscription;

use Mouse;

has master_id => (
    isa => 'Int',
    is  => 'rw'
);

has master_type => (
    isa => 'Str',
    is  => 'rw'
);

has human_id => (
    isa => 'Int',
    is  => 'rw'
);

sub create {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/INSERT INTO `subscription` (master_type, master_id, human_id)
            VALUES (?, ?, ?)/ =>
          ($args->{master_type}, $args->{master_id}, $args->{human_id}) =>
          sub {
            my ($dbh, $rows, $rv) = @_;

            my $subscription = Hamster::Subscription->new(%$args);

            return $cb->($dbh, $subscription);
        }
    );
}

sub find {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/SELECT master_type, master_id, human_id
            FROM `subscription` WHERE `master_type`=? AND master_id=?/
        => ($args->{master_type}, $args->{master_id}) => sub {
            my ($dbh, $rows, $rv) = @_;

            if (@$rows) {
                my $row = $rows->[0];

                my $subscription = Hamster::Subscription->new(
                    master_type => $row->[0],
                    master_id   => $row->[1],
                    human_id    => $row->[2],
                );

                return $cb->($dbh, $subscription);
            }
            else {
                return $cb->($dbh);
            }
        }
    );
}

sub find_all {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/SELECT master_type, master_id, human_id
            FROM `subscription` WHERE `master_type`=? AND human_id=?/
        => ($args->{master_type}, $args->{human_id}) => sub {
            my ($dbh, $rows, $rv) = @_;

            if (@$rows) {
                my $subscriptions = [];

                foreach my $row (@$rows) {
                    my $subscription = Hamster::Subscription->new(
                        master_type => $row->[0],
                        master_id   => $row->[1],
                        human_id    => $row->[2],
                    );

                    push @$subscriptions, $subscription;
                }

                return $cb->($dbh, $subscriptions);
            }
            else {
                return $cb->($dbh);
            }
        }
    );
}

sub delete {
    my $self = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/DELETE FROM `subscription` WHERE master_type=? AND master_id=? AND human_id=?/
          => ($self->master_type, $self->master_id, $self->human_id) => sub {
            my ($dbh, $rows, $rv) = @_;

            return $cb->($dbh);
        }
    );
}

1;

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

use Hamster::Human;
use Hamster::JID;
use Hamster::Subscription;

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

sub exists {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/SELECT COUNT(*)
            FROM `subscription` WHERE `master_type`=? AND master_id=? AND human_id=?/
        => ($args->{master_type}, $args->{master_id}, $args->{human_id}) => sub {
            my ($dbh, $rows, $rv) = @_;

            if (@$rows && $rows->[0]->[0] > 0) {
                return $cb->($dbh, 1);
            }
            else {
                return $cb->($dbh, 0);
            }
        }
    );
}

sub create_unless_exists {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    Hamster::Subscription->exists(
        $dbh, $args,
        sub {
            my ($dbh, $exists) = @_;

            if ($exists) {
                return $cb->($dbh);
            }
            else {
                Hamster::Subscription->create(
                    $dbh, $args,
                    sub {
                        return $cb->(@_);
                    }
                );
            }
        }
    );
}

sub find {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/SELECT master_type, master_id, human_id
            FROM `subscription` WHERE `master_type`=? AND master_id=? AND human_id=?/
        => ($args->{master_type}, $args->{master_id}, $args->{human_id}) => sub {
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

sub find_subscribed_humans {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/SELECT subscription.human_id,human.nick,jid.id,jid.jid
            FROM `subscription`
            JOIN human ON human.id=subscription.human_id
            JOIN jid ON jid.human_id=subscription.human_id
            WHERE `master_type`=? AND master_id=? AND human.id!=?/
        => ($args->{master_type}, $args->{master_id}, $args->{except_human_id}) => sub {
            my ($dbh, $rows, $rv) = @_;

            use Data::Dumper;
            warn Dumper $args;
            warn Dumper $rows;

            my $humans = [];

            my $h = {};
            foreach my $row (@$rows) {
                my $human = $h->{$row->[0]};

                $human ||= Hamster::Human->new(
                    id   => $row->[0],
                    nick => $row->[1]
                );

                $human->add_jid(Hamster::JID->new(id => $row->[2], jid => $row->[3]));

                unless ($h->{$row->[0]}) {
                    $h->{$row->[0]} = $human;
                    push @$humans, $human;
                }
            }

            return $cb->($dbh, $humans);
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

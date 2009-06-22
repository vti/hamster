package Hamster::JID;

use Mouse;

has id => (
    isa => 'Int',
    is  => 'rw'
);

has jid => (
    isa => 'Str',
    is  => 'rw'
);

sub create {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        'INSERT INTO `jid` (`human_id`,`jid`) VALUES (?, ?)' =>
          ($args->{human_id}, $args->{jid}) => sub {
            $dbh->func(
                q/undef, undef, 'jid', 'id'/ => last_insert_id => sub {
                    my ($dbh, $result, $handle_error) = @_;

                    my $jid = Hamster::JID->new(
                        id       => $result,
                        human_id => $args->{human_id},
                        jid      => $args->{jid}
                    );

                    $cb->($dbh, $jid);
                }
            );
        }
    );
}

sub find_all {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        'SELECT id, human_id, jid FROM jid WHERE human_id=?' =>
          ($args->{human_id}) => sub {
            my ($dbh, $rows, $rv) = @_;

            my $jids = [];

            foreach my $row (@$rows) {
                push @$jids,
                  Hamster::JID->new(
                    id       => $row->[0],
                    human_id => $row->[1],
                    jid      => $row->[2]
                  );
            }

            return $cb->($dbh, $jids);
        }
    );
}

1;

package Hamster::Human;

use Mouse;

use Hamster::Human::JID;

has id => (
    isa => 'Int',
    is  => 'rw'
);

has nick => (
    isa => 'Str',
    is  => 'rw'
);

has jids => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] }
);

has jid => (
    isa => 'Str',
    is  => 'rw'
);

has resource => (
    isa => 'Str',
    is  => 'rw'
);

has lang => (
    isa     => 'Str',
    is      => 'rw',
    default => 'en'
);

sub find {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/SELECT human.id, human.nick, human.lang
            FROM `human`
            JOIN `jid` ON `human`.`id` = `human_id` WHERE `jid`=?/,
        $args->{jid},
        sub {
            my ($dbh, $rows, $rv) = @_;

            if (@$rows) {
                my $row = $rows->[0];

                my $human = Hamster::Human->new(
                    id       => $row->[0],
                    lang     => $row->[2],
                    jid      => $args->{jid},
                    resource => $args->{resource}
                );

                $human->nick($row->[1]) if $row->[1];

                $dbh->exec(
                    qq/SELECT * FROM `jid` WHERE `human_id`=?/,
                    $human->id,
                    sub {
                        my ($dbh, $rows, $rv) = @_;

                        foreach my $jid (@$rows) {
                            $human->add_jid($jid->[0], $jid->[2]);
                        }

                        return $cb->($dbh, $human);
                    }
                );
            }
            else {
                return $cb->($dbh);
            }
        }
    );
}

sub create {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        'INSERT INTO `human` (`addtime`,`nick`) VALUES (?, ?)' => (time, $args->{nick}) => sub {
            my ($rs, $rows, $rv) = @_;

            $dbh->func(
                q/undef, undef, 'human', 'id'/ => last_insert_id => sub {
                    my ($dbh, $result, $handle_error) = @_;

                    $dbh->exec(
                        'INSERT INTO `jid` (`human_id`,`jid`) VALUES (?, ?)' =>
                        ($result, $args->{jid}) => sub {
                            $dbh->func(
                                q/undef, undef, 'jid', 'id'/ =>
                                  last_insert_id => sub {
                                    my ($dbh, $result, $handle_error) = @_;

                                    my $human = Hamster::Human->new(
                                        id       => $result,
                                        resource => $args->{resource}
                                    );

                                    $human->nick($args->{nick}) if $args->{nick};

                                    $human->add_jid($result, $args->{jid});

                                    $cb->($dbh, $human);
                                }
                            );
                        }
                    );
                }
            );
        }
    );
}

sub update_nick {
    my $self = shift;
    my ($dbh, $args, $cb) = @_;

    my $nick = $args->{nick};

    $dbh->exec(
        qq/SELECT nick FROM `human` WHERE `nick`=?/ => ($nick) => sub {
            my ($dbh, $rows, $rv) = @_;

            if (@$rows) {
                return $cb->($dbh, 0);
            }
            else {
                $dbh->exec(
                    qq/UPDATE human SET nick=? WHERE id=?/ =>
                      ($nick, $self->id) => sub {
                        my ($dbh, $rows, $rv) = @_;

                        return $cb->($dbh, 1);
                    }
                );
            }
        }
    );
}

sub update_lang {
    my $self = shift;
    my ($dbh, $args, $cb) = @_;

    my $lang = $args->{lang};

    $dbh->exec(
        qq/UPDATE human SET lang=? WHERE `id`=?/ =>
          ($lang, $self->id) => sub {
            my ($dbh, $rows, $rv) = @_;

            return $cb->();
        }
    );
}

sub add_jid {
    my $self = shift;

    if (@_) {
        push @{$self->jids},
          Hamster::Human::JID->new(id => $_[0], jid => $_[1]);
    }
}

1;

package Hamster::Reply;

use Mouse;

has topic_id => (
    isa => 'Int',
    is  => 'rw'
);

has seq => (
    isa => 'Int',
    is  => 'rw'
);

has body => (
    isa => 'Str',
    is  => 'rw'
);

has author => (
    isa => 'Str',
    is  => 'rw'
);

has human_id => (
    isa => 'Int',
    is  => 'rw'
);

has parent_body => (
    isa => 'Str',
    is  => 'rw'
);

has parent_author => (
    isa => 'Str',
    is  => 'rw'
);

has parent_body_max_length => (
    isa     => 'Int',
    is      => 'rw',
    default => 77
);

sub _create {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    my $topic = $args->{topic};
    my $human = $args->{human};

    Hamster::Reply->find_current_seq(
        $dbh,
        {topic_id => $topic->id},
        sub {
            my ($dbh, $seq) = @_;

            $seq = $seq ? $seq + 1 : 1;

            $dbh->exec(
                qq/INSERT INTO `reply`
                    (topic_id, seq, parent_seq, addtime, human_id, body, jid, resource)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)/
                  => (
                    $topic->id, $seq, $args->{parent_seq}, time,
                    $human->id,
                    $args->{body}, $args->{jid}, $args->{resource}
                  ) => sub {
                    my ($dbh, $rows, $rv) = @_;

                    $dbh->func(
                        q/undef, undef, 'topic', 'id'/,
                        'last_insert_id',
                        sub {
                            my ($dbh, $result, $handle_error) = @_;

                            my $reply = Hamster::Reply->new(
                                seq      => $seq,
                                body     => $args->{body},
                                human_id => $human->id,
                                author => $args->{human}->nick || $args->{jid}
                            );

                            $topic->inc_replies(
                                $dbh,
                                sub {
                                    $cb->($dbh, $reply);
                                }
                            );
                        }
                    );
                }
            );
        }
    );
}

sub create {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    my $topic = $args->{topic};

    if ($args->{parent_seq}) {
        Hamster::Reply->find(
            $dbh,
            {   topic_id => $topic->id,
                seq      => $args->{parent_seq}
            },
            sub {
                my ($dbh, $parent) = @_;

                if ($parent) {
                    Hamster::Reply->_create(
                        $dbh,
                        $args,
                        sub {
                            my ($dbh, $reply) = @_;

                            $reply->_quote_parent($parent->author,
                                $parent->body);

                            return $cb->($dbh, $reply);
                        }
                    );
                }
                else {
                    return $cb->($dbh);
                }
            }
        );
    }
    else {
        Hamster::Reply->_create(
            $dbh,
            $args,
            sub {
                my ($dbh, $reply) = @_;

                return $cb->($dbh, $reply);
            }
        );
    }
}

sub find_current_seq {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/SELECT seq FROM `reply` WHERE `topic_id`=? ORDER BY seq DESC LIMIT 1/
          => ($args->{topic_id}) => sub {
            my ($dbh, $rows, $rv) = @_;

            if (@$rows) {
                $cb->($dbh, $rows->[0]->[0]);
            }
            else {
                $cb->($dbh);
            }
        }
    );
}

sub find {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/SELECT reply.topic_id, reply.seq, reply.human_id, reply.body,
            reply.jid, reply.resource, human.nick
            FROM `reply`
            LEFT JOIN human ON human.id=reply.human_id
            WHERE topic_id=? AND seq=?/ =>
          ($args->{topic_id}, $args->{seq}) => sub {
            my ($dbh, $rows, $rv) = @_;

            if (@$rows) {
                my $row = $rows->[0];

                my $reply = Hamster::Reply->new(
                    topic_id => $row->[0],
                    seq      => $row->[1],
                    human_id => $row->[2],
                    body     => $row->[3],
                    author   => $row->[6] || $row->[4]
                );

                return $cb->($dbh, $reply);
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
        qq/SELECT reply.topic_id, reply.seq, reply.body, reply.jid,
                human.nick,
                parent.body, parent.jid,
                parent_human.nick
            FROM `reply`
            LEFT JOIN human ON human.id=reply.human_id
            LEFT JOIN reply AS parent
                ON parent.topic_id=reply.topic_id
                    AND parent.seq=reply.parent_seq
            LEFT JOIN human AS parent_human
                ON parent_human.id=parent.human_id
            WHERE reply.topic_id=? ORDER BY reply.seq ASC/ => ($args->{topic_id}) =>
          sub {
            my ($dbh, $rows, $rv) = @_;

            my $replies = [];

            foreach my $row (@$rows) {
                my $reply = Hamster::Reply->new(
                    topic_id => $row->[0],
                    seq      => $row->[1],
                    author   => $row->[4] || $row->[3],
                    body     => $row->[2]
                );

                $reply->_quote_parent($row->[7] || $row->[6], $row->[5]);

                push @$replies, $reply;
            }

            return $cb->($dbh, $replies);
        }
    );
}

sub _quote_parent {
    my $self = shift;
    my ($parent_author, $parent_body) = @_;

    return unless $parent_author;

    if (length($parent_body) > $self->parent_body_max_length) {
        $parent_body .= substr($parent_body, 0,
            $self->parent_body_max_length);
        $parent_body .= '...';
    }
    else {
        $parent_body .= $parent_body;
    }

    $self->parent_author($parent_author);
    $self->parent_body($parent_body);
}

1;

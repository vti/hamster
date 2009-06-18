package Hamster::Topic;

use Mouse;

has id => (
    isa => 'Int',
    is  => 'rw'
);

has body => (
    isa => 'Str',
    is  => 'rw'
);

has resource => (
    isa => 'Str',
    is  => 'rw'
);

has replies => (
    isa     => 'Int',
    is      => 'rw',
    default => 0
);

has author => (
    isa => 'Str',
    is  => 'rw'
);

use Async::Hooks;

sub create {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/INSERT INTO `topic` (human_id, addtime, body, jid, resource) VALUES (?, ?, ?, ?, ?)/ =>
          ($args->{human_id}, time, $args->{body}, $args->{jid}, $args->{resource}) => sub {
            my ($dbh, $rows, $rv) = @_;

            $dbh->func(q/undef, undef, 'topic', 'id'/ => last_insert_id => sub {
                    my ($dbh, $result, $handle_error) = @_;

                    my $hooks = Async::Hooks->new;

                    foreach my $tag (@{$args->{tags}}) {
                        $hooks->hook('insert_tag', \&_insert_tag_hook);
                    }

                    $hooks->call(
                        'insert_tag',
                        [$dbh, $result, $args->{tags}],
                        sub {
                            my ($ctl, $a, $is_done) = @_;

                            my $topic = Hamster::Topic->new(
                                id       => $result,
                                human_id => $args->{human_id},
                                body     => $args->{body},
                                jid      => $args->{jid},
                                resource => $args->{resource}
                            );

                            return $cb->($dbh, $topic);
                        }
                    );
                }
            );
        }
    );
}

sub find {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/SELECT topic.human_id, topic.body, topic.replies,
            topic.jid, topic.resource, human.nick
            FROM topic
            LEFT JOIN human ON human.id=topic.human_id
            WHERE topic.id=?/ => ($args->{id}) => sub {
            my ($dbh, $rows, $rv) = @_;

            if (@$rows) {
                my $row = $rows->[0];

                my $topic = Hamster::Topic->new(
                    id       => $args->{id},
                    human_id => $row->[0],
                    body     => $row->[1],
                    replies  => $row->[2],
                    author   => $row->[5] || $row->[3]
                );

                return $cb->($dbh, $topic);
            }
            else {
                return $cb->($dbh);
            }
        }
    );
}

sub inc_replies {
    my ($self, $dbh, $cb) = @_;

    $dbh->exec(
        qq/UPDATE topic SET replies = replies + 1 WHERE `id`=?/ =>
          ($self->id) => sub {
            my ($dbh, $rows, $rv) = @_;

            $self->replies($self->replies + 1);

            $cb->($dbh);
        }
    );
}

sub find_all {
    my $class = shift;
    my ($dbh, $args, $cb) = @_;

    $dbh->exec(
        qq/SELECT topic.id, topic.body, topic.replies, topic.jid, human.nick FROM `topic`
            LEFT JOIN human ON human.id=topic.human_id
            ORDER BY topic.addtime DESC LIMIT 10/ =>
          sub {
            my ($dbh, $rows, $rv) = @_;

            @$rows = reverse @$rows;

            my $topics = [];

            foreach my $row (@$rows) {
                my $topic = Hamster::Topic->new(
                    id      => $row->[0],
                    body    => $row->[1],
                    replies => $row->[2],
                    author  => $row->[4] || $row->[3]
                );

                push @$topics, $topic;
            }

            return $cb->($dbh, $topics);
        }
    );
}

sub _insert_tag_hook {
    my ($ctl, $args) = @_;
    my ($dbh, $topic_id, $tags) = @$args;

    my $title = shift @$tags;

    $dbh->exec(
        qq/SELECT * FROM `tag` WHERE `title` = ?/,
        ($title) => sub {
            my ($dbh, $rows, $rv) = @_;

            if (@$rows) {
                return _insert_tag_map($dbh, $rows->[0]->[0],
                    $topic_id, sub { $ctl->next; });
            }
            else {
                $dbh->exec(
                    qq/INSERT INTO `tag` (title) VALUES (?)/ => ($title) =>
                      sub {
                        my ($dbh, $rows, $rv) = @_;

                        $dbh->func(
                            q/undef, undef, 'topic', 'id'/,
                            'last_insert_id',
                            sub {
                                my ($dbh, $result, $handle_error) = @_;

                                _insert_tag_map($dbh, $result, $topic_id,
                                    sub { $ctl->next; });
                            }
                        );
                    }
                );
            }
        }
    );
}

sub _insert_tag_map {
    my ($dbh, $tag_id, $topic_id, $cb) = @_;

    $dbh->exec(
        qq/INSERT INTO `tag_map` (tag_id, topic_id) VALUES (?,?)/ =>
          ($tag_id, $topic_id) => sub {
            my ($dbh, $rows, $rv) = @_;

            return $cb->();
        }
    );
}

1;

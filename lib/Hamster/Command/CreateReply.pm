package Hamster::Command::CreateReply;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    my ($id, $parent_seq, $body) = @{$self->args};

    my $dbh = $self->hamster->dbh;

    $dbh->exec(
        qq/SELECT body,replies FROM `topic` WHERE `id`=?/ => ($id) => sub {
            my ($dbh, $rows, $rv) = @_;

            # If we found topic
            if (@$rows) {
                my $topic = $rows->[0];

                # If there are replies
                if ($topic->[1]) {
                    $dbh->exec(
                        qq/SELECT seq FROM `reply` WHERE `topic_id`=? ORDER BY seq DESC LIMIT 1/
                          => ($id) => sub {
                            my ($dbh, $rows, $rv) = @_;

                            use Data::Dumper;
                            warn Dumper $rows;

                            my $reply = $rows->[0];

                            if ($parent_seq) {
                                _insert_reply_to(
                                    (   $self, $dbh,  $id,
                                        $body, $reply->[0] + 1,
                                        $parent_seq
                                    ) => sub {
                                        my ($dbh) = @_;

                                        if ($dbh) {
                                            _inc_replies($dbh, $id,
                                                sub { $cb->() });
                                        }
                                        else {
                                            return $cb->();
                                        }
                                    }
                                );
                            }
                            else {
                                _insert_reply(
                                    ($self, $dbh, $id, $body, $rows->[1] + 1,
                                        undef) => sub {
                                        my ($dbh) = @_;

                                        _inc_replies($dbh, $id,
                                            sub { $cb->() });
                                    }
                                );
                            }
                        }
                    );
                }

                # There are no replies, thus we insert the first one
                else {
                    _insert_reply(
                        ($self, $dbh, $id, $body, 1, undef) => sub {
                            _inc_replies($self, $dbh, $id, sub { $cb->() });
                        }
                    );
                }
            }
            else {
                my $reply = $self->msg->make_reply;

                $reply->add_body("Topic was not found");

                $reply->send;

                return $cb->();
            }
        }
    );
}

sub _insert_reply_to {
    my ($self, $dbh, $topic_id, $body, $seq, $parent_seq, $cb) = @_;

    warn 'REPLY TO!';
    $dbh->exec(
        qq/SELECT seq FROM `reply` WHERE topic_id=? AND seq=?/ =>
          ($topic_id, $parent_seq) => sub {
            my ($dbh, $rows, $rv) = @_;

            # If we found reply
            if (@$rows) {
                _insert_reply($self, $dbh, $topic_id, $body, $seq, $parent_seq,
                    sub { $cb->(); });
            }
            else {
                my $reply = $self->msg->make_reply;

                warn 'REPLY WAS NOT FOUND!';

                $reply->add_body("Reply was not found");

                $reply->send;

                $cb->();
            }
        }
    );
}

sub _insert_reply {
    my ($self, $dbh, $topic_id, $body, $seq, $parent_seq, $cb) = @_;

    $dbh->exec(
        qq/INSERT INTO `reply` (topic_id, seq, parent_seq, addtime, jid_id, body, resource)
            VALUES (?, ?, ?, ?, ?, ?, ?)/
          => (
            $topic_id, $seq, $parent_seq, time,
            $self->human->jid($self->msg->from)->id,
            $body, $self->human->resource
          ) => sub {
            my ($dbh, $rows, $rv) = @_;

            $dbh->func(
                q/undef, undef, 'topic', 'id'/,
                'last_insert_id',
                sub {
                    my ($dbh, $result, $handle_error) = @_;

                    my $reply = $self->msg->make_reply;

                    $reply->add_body("Reply was created #$topic_id/$seq");

                    $reply->send;

                    return $cb->($dbh);
                }
            );
        }
    );
}

sub _inc_replies {
    my ($self, $dbh, $topic_id, $cb) = @_;

    $dbh->exec(
        qq/UPDATE topic SET replies = replies + 1 WHERE `id`=?/ =>
          ($topic_id) => sub {
            my ($dbh, $rows, $rv) = @_;

            $cb->();
        }
    );
}

1;

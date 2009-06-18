package Hamster::Command::CreateReply;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($human, $msg, $cb) = @_;

    my ($id) = ($msg->any_body =~ m/^#(\d+)/);

    my $body = $msg->any_body;
    $body =~ s/^#\d+\s*//;

    my $dbh = $self->hamster->dbh;

    $dbh->exec(
        qq/SELECT * FROM `topic` WHERE `id`=?/ => ($id) => sub {
            my ($dbh, $rows, $rv) = @_;

            # If we found topic
            if (@$rows) {

                use Data::Dumper;
                warn Dumper $rows;
                warn "replies=" . $rows->[0]->[5];

                # If there are replies
                if ($rows->[0]->[5]) {
                    $dbh->exec(
                        qq/SELECT * FROM `reply` WHERE `topic_id`=? ORDER BY seq DESC LIMIT 1/
                          => ($id) => sub {
                            my ($dbh, $rows, $rv) = @_;

                            use Data::Dumper;
                            warn Dumper $rows;

                            _insert_reply(
                                (   $dbh,  $human,
                                    $msg,  $id,
                                    $body, $rows->[0]->[1] + 1
                                ) => sub {
                                    my ($dbh) = @_;

                                    _inc_replies($dbh, $id, sub { $cb->() });
                                }
                            );
                        }
                    );
                }

                # There are no replies, thus we insert the first one
                else {
                    _insert_reply(
                        ($dbh, $human, $msg, $id, $body, 1) => sub {
                            _inc_replies($dbh, $id, sub { $cb->() });
                        }
                    );
                }
            }
            else {
                my $reply = $msg->make_reply;

                $reply->add_body("Topic was not found");

                $reply->send;

                return $cb->();
            }
        }
    );
}

sub _insert_reply {
    my ($dbh, $human, $msg, $topic_id, $body, $seq, $cb) = @_;

    $dbh->exec(
        qq/INSERT INTO `reply` (topic_id, seq, addtime, jid_id, body, resource)
            VALUES (?, ?, ?, ?, ?, ?)/
          => (
            $topic_id, $seq,
            time,      $human->jid($msg->from)->id,
            $body,     $human->resource
          ) => sub {
            my ($dbh, $rows, $rv) = @_;

            $dbh->func(
                q/undef, undef, 'topic', 'id'/,
                'last_insert_id',
                sub {
                    my ($dbh, $result, $handle_error) = @_;

                    my $reply = $msg->make_reply;

                    $reply->add_body("Reply was created #$topic_id/$seq");

                    $reply->send;

                    return $cb->($dbh);
                }
            );
        }
    );
}

sub _inc_replies {
    my ($dbh, $topic_id, $cb) = @_;

    $dbh->exec(
        qq/UPDATE topic SET replies = replies + 1 WHERE `id`=?/ =>
          ($topic_id) => sub {
            my ($dbh, $rows, $rv) = @_;

            $cb->();
        }
    );
}

1;

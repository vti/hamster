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
        qq/SELECT body FROM `topic` WHERE `id`=?/ => ($id) => sub {
            my ($dbh, $rows, $rv) = @_;

            if (@$rows) {
                $dbh->exec(
                    qq/INSERT INTO `reply` (topic_id, addtime, body, resource) VALUES (?, ?, ?, ?)/
                      => ($id, time, $body, $human->resource) => sub {
                        my ($dbh, $rows, $rv) = @_;

                        $dbh->func(
                            q/undef, undef, 'topic', 'id'/,
                            'last_insert_id',
                            sub {
                                my ($dbh, $result, $handle_error) = @_;

                                my $reply = $msg->make_reply;

                                $reply->add_body(
                                    "Reply was created #$id/$result");

                                $reply->send;

                                return $cb->();
                            }
                        );
                    }
                );
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

1;

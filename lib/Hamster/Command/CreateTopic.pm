package Hamster::Command::CreateTopic;

use Mouse;

extends 'Hamster::Command::Base';

use Async::Hooks;

sub run {
    my $self = shift;
    my ($human, $msg, $cb) = @_;

    my $body = $msg->any_body;

    my ($text, $tags) = $self->_parse($body);

    my $dbh = $self->hamster->dbh;

    $dbh->exec(
        qq/INSERT INTO `topic` (jid_id, addtime, body, resource) VALUES (?, ?, ?, ?)/ =>
          ($human->id, time, $text, $human->resource) => sub {
            my ($dbh, $rows, $rv) = @_;

            $dbh->func(
                q/undef, undef, 'topic', 'id'/,
                'last_insert_id',
                sub {
                    my ($dbh, $result, $handle_error) = @_;

                    my $hooks = Async::Hooks->new;

                    foreach my $tag (@$tags) {
                        $hooks->hook('insert_tag', \&_insert_tag_hook);
                    }

                    $hooks->call(
                        'insert_tag',
                        [$dbh, $result, $tags],
                        sub {
                            my ($ctl, $args, $is_done) = @_;

                            my $reply = $msg->make_reply;

                            $reply->add_body(
                                "Topic '$text' was created #$result");

                            $reply->send;

                            return $cb->();
                        }
                    );
                }
            );
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

sub _parse {
    my $self = shift;
    my $msg  = shift;
    return unless $msg;

    my $tags = $self->_parse_tags(\$msg);

    return ($msg, $tags);
}

sub _parse_tags {
    my $self = shift;
    my $msg  = shift;

    my @tags = ();

    while ($$msg =~ s/^\*([^\s]+)\s*//) {
        push @tags, $1;
    }

    return \@tags;
}

1;

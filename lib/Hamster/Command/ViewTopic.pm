package Hamster::Command::ViewTopic;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($human, $msg, $cb) = @_;

    my $dbh = $self->hamster->dbh;

    my ($id, $show_replies) = ($msg->any_body =~ m/^#(\d+)(\+)?$/);

    $dbh->exec(
        qq/SELECT body,replies,jid.jid,human.nick FROM `topic`
            JOIN jid ON jid.id=topic.jid_id
            JOIN human ON human.id=jid.human_id
            WHERE topic.`id`=?/ =>
          ($id) => sub {
            my ($dbh, $rows, $rv) = @_;

            use Data::Dumper;
            warn Dumper $rows;

            my $reply = $msg->make_reply;

            if (@$rows) {
                my $topic = $rows->[0];

                my $replies = $topic->[1];
                my $nick = $topic->[3] || $topic->[2];

                my $body = <<"";
#$id by $nick (Replies: $replies)
$topic->[0]

                if ($show_replies && $replies) {
                    return $dbh->exec(
                        qq/SELECT reply.topic_id, reply.seq, reply.body,
                                jid.jid, human.nick,
                                parent_jid.jid,parent_human.nick
                            FROM `reply`
                            JOIN jid ON jid.id=reply.jid_id
                            JOIN human ON human.id=jid.human_id
                            LEFT JOIN reply AS parent
                                ON parent.topic_id=reply.topic_id
                                    AND parent.seq=reply.parent_seq
                            LEFT JOIN jid AS parent_jid
                                ON parent_jid.id=parent.jid_id
                            LEFT JOIN human AS parent_human
                                ON parent_human.id=parent_jid.human_id
                            WHERE reply.topic_id=? ORDER BY reply.seq ASC/ => ($id) =>
                          sub {
                            my ($dbh, $rows, $rv) = @_;

                            use Data::Dumper;
                            warn Dumper $rows;

                            foreach my $row (@$rows) {
                                my $nick = $row->[4] || $row->[3];
                                my $parent_nick = $row->[6] || $row->[5];

                                my $reply_to = '';
                                $reply_to = "\@$parent_nick, " if $parent_nick;

                                $body .= <<"";
#$row->[0]/$row->[1] by $nick
$reply_to$row->[2]

                            }

                            warn $body;
                            $reply->add_body($body);

                            $reply->send;

                            return $cb->();
                        }
                    );
                }
                else {
                    $reply->add_body($body);
                }
            }
            else {
                $reply->add_body("Topic was not found");
            }

            $reply->send;

            return $cb->();
        }
    );
}

1;

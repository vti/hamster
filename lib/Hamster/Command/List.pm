package Hamster::Command::List;

use Mouse;

extends 'Hamster::Command::Base';

sub run {
    my $self = shift;
    my ($cb) = @_;

    my $dbh = $self->hamster->dbh;

    $dbh->exec(
        qq/SELECT topic.id,topic.body,topic.replies,jid.jid,human.nick FROM `topic`
            JOIN jid ON jid.id=topic.jid_id
            JOIN human ON human.id=jid.human_id
            ORDER BY topic.addtime DESC LIMIT 10/ =>
          sub {
            my ($dbh, $rows, $rv) = @_;

            my $reply = $self->msg->make_reply;

            @$rows = reverse @$rows;

            if (@$rows) {
                my $body = '';

                foreach my $topic (@$rows) {
                    my $replies = $topic->[2];
                    my $nick = $topic->[3] || $topic->[2];

                    $body
                      .= $self->hamster->localizator->loc($self->human->lang,
                        '#[_1] by [_2] (Replies: [_3])',
                        $topic->[0], $nick, $replies) . "\n";
                    $body .= $topic->[1] . "\n";

                }

                warn $body;

                $reply->add_body($body);
            }
            else {
                $reply->add_body("No topics yet");
            }

            $reply->send;

            return $cb->();
        }
    );
}

1;

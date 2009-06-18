package Hamster::Command::ViewTopic;

use Mouse;

extends 'Hamster::Command::Base';

use Hamster::Topic;
use Hamster::Reply;

sub run {
    my $self = shift;
    my ($cb) = @_;

    my $dbh = $self->hamster->dbh;

    my ($id, $show_replies) = @{$self->args};

    Hamster::Topic->find(
        $dbh,
        {id => $id},
        sub {
            my ($dbh, $topic) = @_;

            if ($topic) {
                my $msg = $self->render(topic => $topic);

                if ($show_replies) {
                    Hamster::Reply->find_all(
                        $dbh,
                        {topic_id => $topic->id},
                        sub {
                            my ($dbh, $replies) = @_;

                            foreach my $reply (@$replies) {
                                $msg .= "\n";
                                $msg .= $self->render(reply => $reply);
                            }

                            return $self->send($msg, sub { $cb->() });
                        }
                    );
                }
                else {
                    return $self->send($msg, sub { $cb->() });
                }
            }
            else {
                return $self->send('Topic not found', sub { $cb->() });
            }
        }
    );
}

1;

package Hamster::Command::CreateReply;

use Mouse;

extends 'Hamster::Command::Base';

use Hamster::Topic;
use Hamster::Reply;

sub run {
    my $self = shift;
    my ($cb) = @_;

    my ($id, $parent_seq, $body) = @{$self->args};

    my $dbh = $self->hamster->dbh;

    my ($jid, $resource) = split('/', $self->msg->from);

    Hamster::Topic->find(
        $dbh,
        {id => $id},
        sub {
            my ($dbh, $topic) = @_;

            if ($topic) {
                Hamster::Reply->create(
                    $dbh,
                    {   topic      => $topic,
                        parent_seq => $parent_seq,
                        human_id   => $self->human->id,
                        body       => $body,
                        jid        => $jid,
                        resource   => $resource
                    },
                    sub {
                        my ($dbh, $reply) = @_;

                        if ($reply) {
                            return $self->send('Reply created',
                                sub { $cb->() });
                        }
                        else {
                            return $self->send('Reply not found',
                                sub { $cb->() });
                        }
                    }
                );
            }
            else {
                return $self->send('Topic not found', sub { $cb->() });
            }
        }
    );
}

1;

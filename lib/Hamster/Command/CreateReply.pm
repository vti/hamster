package Hamster::Command::CreateReply;

use Mouse;

extends 'Hamster::Command::Base';

use Hamster::Topic;
use Hamster::Reply;
use Hamster::Subscription;

use Hamster::Service::Notify;

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
                        human      => $self->human,
                        body       => $body,
                        jid        => $jid,
                        resource   => $resource
                    },
                    sub {
                        my ($dbh, $reply) = @_;

                        if ($reply) {
                            Hamster::Subscription->create_unless_exists(
                                $dbh,
                                {   master_type => 't',
                                    master_id   => $topic->id,
                                    human_id    => $self->human->id
                                },
                                sub {
                                    $self->send(
                                        'Reply created',
                                        sub {
                                            _notify_subscribers($self, $dbh,
                                                $topic, $reply,
                                                sub { $cb->() });
                                        }
                                    );
                                }
                            );
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

sub _notify_subscribers {
    my ($self, $dbh, $topic, $reply, $cb) = @_;

    Hamster::Subscription->find_subscribed_humans(
        $dbh,
        {   master_type     => 't',
            master_id       => $topic->id,
            except_human_id => $reply->human_id
        },
        sub {
            my ($dbh, $humans) = @_;

            use Data::Dumper;
            warn Dumper $humans;

            if (@$humans) {
                my $service =
                  Hamster::Service::Notify->new(hamster => $self->hamster);

                $service->run(
                    sub {
                        my $human = shift;
                        $self->hamster->view->reply($human->lang, $reply);
                    },
                    $humans,
                    sub { $cb->() }
                );
            }
            else {
                return $cb->();
            }
        }
    );
}

1;

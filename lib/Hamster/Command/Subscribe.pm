package Hamster::Command::Subscribe;

use Mouse;

extends 'Hamster::Command::Base';

use Hamster::Topic;
use Hamster::Subscription;

sub run {
    my $self = shift;
    my ($cb) = @_;

    my ($type, $id) = @{$self->args};

    if (!$type) {
        Hamster::Subscription->find_all(
            $self->hamster->dbh,
            {   master_type => 't',
                human_id    => $self->human->id
            },
            sub {
                my ($dbh, $subscriptions) = @_;

                $subscriptions ||= [];

                return $self->send(
                    $self->render(subscriptions => $subscriptions),
                    sub { $cb->() });
            }
        );
    }
    elsif ($type eq '#') {
        my $dbh = $self->hamster->dbh;

        Hamster::Topic->find(
            $dbh,
            {id => $id},
            sub {
                my ($dbh, $topic) = @_;

                if ($topic) {
                    Hamster::Subscription->create_unless_exists(
                        $dbh,
                        {   master_type => 't',
                            master_id   => $id,
                            human_id    => $self->human->id
                        },
                        sub {
                            my ($dbh, $subscription) = @_;

                            $self->send('You were subscribed',
                                sub { $cb->() });
                        }
                    );
                }
                else {
                    return $self->send('Topic not found', sub { $cb->() });
                }
            }
        );
    }

    return $cb->();
}

1;

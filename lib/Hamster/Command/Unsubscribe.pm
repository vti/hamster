package Hamster::Command::Unsubscribe;

use Mouse;

extends 'Hamster::Command::Base';

use Hamster::Topic;
use Hamster::Subscription;

sub run {
    my $self = shift;
    my ($cb) = @_;

    my ($type, $id) = @{$self->args};

    if ($type eq '#') {
        my $dbh = $self->hamster->dbh;

        Hamster::Topic->find(
            $dbh,
            {id => $id},
            sub {
                my ($dbh, $topic) = @_;

                if ($topic) {
                    Hamster::Subscription->find(
                        $dbh,
                        {   master_type => 't',
                            master_id   => $id,
                            human_id    => $self->human->id
                        },
                        sub {
                            my ($dbh, $subscription) = @_;

                            if ($subscription) {
                                $subscription->delete(
                                    $dbh,
                                    {},
                                    sub {
                                        $self->send('You are unsubscribed',
                                            sub { $cb->() });
                                    }
                                );
                            }
                            else {
                                return $self->send('You are not subscribed',
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
}

1;

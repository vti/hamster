use strict;
use warnings;

use Test::More tests => 7;

use lib 't/lib';

use TestDB;
use AnyEvent;

use_ok('Hamster::Subscription');

my $cv = AnyEvent->condvar;

my $dbh = TestDB->dbh;

Hamster::Subscription->find(
    $dbh,
    {},
    sub {
        my ($dbh, $subscription) = @_;
        ok(not defined $subscription);

        Hamster::Subscription->create(
            $dbh,
            {   human_id    => 1,
                master_type => 't',
                master_id   => 1
            },
            sub {
                my ($dbh, $subscription) = @_;

                ok($subscription);

                Hamster::Subscription->find(
                    $dbh,
                    {master_id => 1, master_type => 't'},
                    sub {
                        my ($dbh, $subscription) = @_;

                        ok($subscription);

                        Hamster::Subscription->create(
                            $dbh,
                            {   human_id    => 1,
                                master_type => 't',
                                master_id   => 2
                            },
                            sub {
                                my ($dbh, $subscription) = @_;

                                ok($subscription);

                                Hamster::Subscription->find_all(
                                    $dbh,
                                    {human_id => 1, master_type => 't'},
                                    sub {
                                        my ($dbh, $subscriptions) = @_;

                                        is(@$subscriptions, 2);

                                        $subscriptions->[0]->delete(
                                            $dbh,
                                            {},
                                            sub {
                                                Hamster::Subscription
                                                  ->find_all(
                                                    $dbh,
                                                    {   human_id    => 1,
                                                        master_type => 't'
                                                    },
                                                    sub {
                                                        my ($dbh,
                                                            $subscriptions)
                                                          = @_;

                                                        is(@$subscriptions,
                                                            1);

                                                        $cv->send;
                                                    }
                                                  );
                                            }
                                        );
                                    }
                                );
                            }
                        );
                    }
                );
            }
        );
    }
);

$cv->wait;

#TestDB->cleanup;

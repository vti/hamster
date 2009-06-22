use strict;
use warnings;

use Test::More tests => 8;

use lib 't/lib';

use TestDB;
use AnyEvent;
use Async::Hooks;

use_ok('Hamster::Subscription');

my $cv = AnyEvent->condvar;

my $dbh = TestDB->dbh;

my $hooks = Async::Hooks->new;

$hooks->hook(
    chain => sub {
        my ($ctl, $args) = @_;

        Hamster::Subscription->find(
            $dbh,
            {},
            sub {
                my ($dbh, $subscription) = @_;
                ok(not defined $subscription);

                $ctl->next;
            }
        );
    }
);

$hooks->hook(
    chain => sub {
        my ($ctl, $args) = @_;

        Hamster::Subscription->create(
            $dbh,
            {   human_id    => 1,
                master_type => 't',
                master_id   => 1
            },
            sub {
                my ($dbh, $subscription) = @_;

                ok($subscription);

                $ctl->next;
            }
        );
    }
);

$hooks->hook(
    chain => sub {
        my ($ctl, $args) = @_;

        Hamster::Subscription->find(
            $dbh,
            {master_id => 1, master_type => 't', human_id => 1},
            sub {
                my ($dbh, $subscription) = @_;

                ok($subscription);

                $ctl->next;
            }
        );
    }
);

$hooks->hook(
    chain => sub {
        my ($ctl, $args) = @_;

        Hamster::Subscription->create_unless_exists(
            $dbh,
            {   human_id    => 1,
                master_type => 't',
                master_id   => 2
            },
            sub {
                my ($dbh, $subscription) = @_;

                ok($subscription);

                $ctl->next;
            }
        );
    }
);

$hooks->hook(
    chain => sub {
        my ($ctl, $args) = @_;

        Hamster::Subscription->create_unless_exists(
            $dbh,
            {   human_id    => 1,
                master_type => 't',
                master_id   => 2
            },
            sub {
                my ($dbh, $subscription) = @_;

                ok(not defined $subscription);

                $ctl->next;
            }
        );
    }
);

$hooks->hook(
    chain => sub {
        my ($ctl, $args) = @_;

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
                        Hamster::Subscription->find_all(
                            $dbh,
                            {   human_id    => 1,
                                master_type => 't'
                            },
                            sub {
                                my ($dbh, $subscriptions) = @_;

                                is(@$subscriptions, 1);

                                $ctl->next;
                            }
                        );
                    }
                );
            }
        );
    }
);

$hooks->hook(chain => sub { $cv->send });

$hooks->call('chain');

$cv->recv;

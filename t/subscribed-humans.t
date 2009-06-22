use strict;
use warnings;

use Test::More tests => 5;

use lib 't/lib';

use TestDB;
use AnyEvent;
use Async::Hooks;

use_ok('Hamster::Subscription');
use_ok('Hamster::Human');
use_ok('Hamster::JID');

my $dbh = TestDB->dbh;

my $humans = [];

my $cv = AnyEvent->condvar;

my $hooks = Async::Hooks->new;

$hooks->hook(
    chain => sub {
        my ($ctl, $args) = @_;

        Hamster::Human->create(
            $dbh,
            {jid => 'foo@foo.com', resource => 'foo'},
            sub {
                my ($dbh, $human) = @_;
                push @$humans, $human;
                $ctl->next;
            }
        );
    }
);

$hooks->hook(
    chain => sub {
        my ($ctl, $args) = @_;

        Hamster::Human->create(
            $dbh,
            {jid => 'foo@foo.biz', resource => 'foo'},
            sub {
                my ($dbh, $human) = @_;
                push @$humans, $human;
                $ctl->next;
            }
        );
    }
);

$hooks->hook(
    chain => sub {
        my ($ctl, $args) = @_;

        Hamster::JID->create(
            $dbh,
            {human_id => $humans->[0]->id, jid => 'bar@bar.com'},
            sub {
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
            {master_id => 1, master_type => 't', human_id => $humans->[0]->id},
            sub {
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
            {master_id => 1, master_type => 't', human_id => $humans->[1]->id},
            sub {
                $ctl->next;
            }
        );
    }
);

$hooks->hook(
    chain => sub {
        my ($ctl, $args) = @_;

        Hamster::Subscription->find_subscribed_humans(
            $dbh,
            {   master_type     => 't',
                master_id       => 1,
                except_human_id => $humans->[1]->id
            },
            sub {
                my ($dbh, $humans) = @_;

                is(@$humans, 1);

                is(@{$humans->[0]->jids}, 2);

                $ctl->next;
            }
        );
    }
);

$hooks->hook(chain => sub { $cv->send });

$hooks->call('chain');

$cv->recv;

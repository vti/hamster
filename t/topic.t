use strict;
use warnings;

use Test::More tests => 8;

use lib 't/lib';

use TestDB;
use AnyEvent;

use_ok('Hamster::Topic');

my $cv = AnyEvent->condvar;

my $dbh = TestDB->dbh;

Hamster::Topic->find(
    $dbh,
    {},
    sub {
        my ($dbh, $topic) = @_;
        ok(not defined $topic);

        Hamster::Topic->create(
            $dbh,
            {   human_id => 1,
                body     => 'body',
                jid      => 'foo@bar.com',
                resource => 'foo'
            },
            sub {
                my ($dbh, $topic) = @_;

                ok($topic);

                Hamster::Topic->find(
                    $dbh,
                    {id => $topic->id},
                    sub {
                        my ($dbh, $topic) = @_;

                        ok($topic);

                        is($topic->replies, 0);

                        $topic->inc_replies(
                            $dbh,
                            sub {
                                is($topic->replies, 1);

                                Hamster::Topic->create(
                                    $dbh,
                                    {   human_id => 1,
                                        body     => 'ydob',
                                        jid      => 'bar@foo.com',
                                        resource => 'foo'
                                    },
                                    sub {
                                        my ($dbh, $topic) = @_;

                                        ok($topic);

                                        Hamster::Topic->find_all(
                                            $dbh,
                                            {},
                                            sub {
                                                my ($dbh, $topics) = @_;

                                                is(@$topics, 2);

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

$cv->wait;

#TestDB->cleanup;

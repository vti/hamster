use strict;
use warnings;

use Test::More tests => 10;

use lib 't/lib';

use TestDB;
use AnyEvent;
use Hamster::Human;
use Hamster::Topic;

use_ok('Hamster::Reply');

my $cv = AnyEvent->condvar;

my $dbh = TestDB->dbh;

my $topic = Hamster::Topic->new(id => 1);
my $human = Hamster::Human->new(id => 1);

Hamster::Reply->find(
    $dbh,
    {},
    sub {
        my ($dbh, $reply) = @_;
        ok(not defined $reply);

        Hamster::Reply->create(
            $dbh,
            {   topic    => $topic,
                human    => $human,
                body     => 'body',
                jid      => 'foo@bar.com',
                resource => 'foo'
            },
            sub {
                my ($dbh, $reply) = @_;

                ok($reply);
                is($reply->seq, 1);

                Hamster::Reply->find(
                    $dbh,
                    {topic_id => $topic->id, seq => $reply->seq},
                    sub {
                        my ($dbh, $reply) = @_;

                        ok($reply);

                        Hamster::Reply->create(
                            $dbh,
                            {   topic    => $topic,
                                human    => $human,
                                body     => 'body',
                                jid      => 'foo@bar.com',
                                resource => 'foo'
                            },
                            sub {
                                my ($dbh, $reply) = @_;

                                ok($reply);
                                is($reply->seq, 2);

                                Hamster::Reply->create(
                                    $dbh,
                                    {   topic      => $topic,
                                        parent_seq => $reply->seq,
                                        human      => $human,
                                        body       => 'body',
                                        jid        => 'foo@bar.com',
                                        resource   => 'foo'
                                    },
                                    sub {
                                        my ($dbh, $reply) = @_;

                                        ok($reply);
                                        is($reply->seq, 3);

                                        Hamster::Reply->find_all(
                                            $dbh,
                                            {topic_id => $topic->id},
                                            sub {
                                                my ($dbh, $replies) = @_;

                                                is(@$replies, 3);

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

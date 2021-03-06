use strict;
use warnings;

use Test::More tests => 11;

use lib 't/lib';

use TestDB;
use AnyEvent;

use_ok('Hamster::Human');
use_ok('Hamster::JID');

my $human = Hamster::Human->new;
ok($human);

my $jid = Hamster::JID->new(id => 1, jid => 'foo@bar.com');

$human->add_jid($jid);

is(@{$human->jids}, 1);

is($human->jids->[0]->jid, qw/foo@bar.com/);

is($human->jid('foo@bar.com'), 'foo@bar.com');

my $cv = AnyEvent->condvar;

my $dbh = TestDB->dbh;

Hamster::Human->find(
    $dbh,
    {},
    sub {
        my ($dbh, $human) = @_;
        ok(not defined $human);

        Hamster::Human->create(
            $dbh,
            {jid => 'foo@bar.com', resource => 'foo', nick => 'nick'},
            sub {
                my ($dbh, $human) = @_;

                ok($human);

                Hamster::Human->find(
                    $dbh,
                    {jid => 'foo@bar.com', resource => 'foo'},
                    sub {
                        my ($dbh, $human) = @_;

                        ok($human);

                        Hamster::Human->create(
                            $dbh,
                            {jid => 'bar@foo.com', resource => 'bar'},
                            sub {
                                my ($dbh, $human) = @_;

                                $human->update_nick(
                                    $dbh,
                                    {nick => 'nick'},
                                    sub {
                                        my ($dbh, $ok) = @_;

                                        is($ok, 0);

                                        $human->update_nick(
                                            $dbh,
                                            {nick => 'kcin'},
                                            sub {
                                                my ($dbh, $ok) = @_;

                                                ok($ok);

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

use strict;
use warnings;

use Test::More tests => 5;

use lib 't/lib';

use MessageMock;
use Hamster;
use Hamster::Human;
use Hamster::Dispatcher;
use Hamster::Command::Ping;

my $hamster = Hamster->new;
my $human   = Hamster::Human->new;

my $d = Hamster::Dispatcher->new(hamster => $hamster);
ok($d);

$d->add_map(qr/^PING$/ => Hamster::Command::Ping->new);

$d->dispatch($human, undef, sub { ok(not defined shift) });

my $msg = _msg('FOO');
$d->dispatch($human, $msg, sub { ok($msg->any_body); });

$msg = _msg('PING');
$d->dispatch($human, $msg, sub { is($msg->any_body, 'PONG'); });

$d->add_map('*' => Hamster::Command::Ping->new);

$msg = _msg('FOO');
$d->dispatch($human, $msg, sub { is($msg->any_body, 'PONG'); });

sub _msg {
    my $mock = MessageMock->new();
    $mock->set_always(any_body => shift);
}

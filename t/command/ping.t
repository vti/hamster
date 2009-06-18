use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use MessageMock;
use Hamster::Command::Ping;

my $cmd = Hamster::Command::Ping->new;
ok($cmd);

my $mock = MessageMock->new();
$mock->set_always(any_body => 'PING');
$cmd->msg($mock);
$cmd->run(sub { is($mock->any_body, 'PONG'); });

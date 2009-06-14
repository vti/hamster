use Test::More tests => 5;

use Hamster::Human;
use Hamster::Dispatcher;
use Hamster::Command::Ping;

my $human = Hamster::Human->new(jid => 'foo@bar.com');

my $d = Hamster::Dispatcher->new;
ok($d);

$d->add_map(PING => Hamster::Command::Ping->new);

my $msg = $d->dispatch;
ok(not defined $msg);

$msg = $d->dispatch(undef, $human, 'FOO');
ok(not defined $msg);

$msg = $d->dispatch(undef, $human, 'PING');
is($msg->body, 'PONG');

$d->add_map(_ => Hamster::Command::Ping->new);

$msg = $d->dispatch(undef, $human, 'FOO');
is($msg->body, 'PONG');

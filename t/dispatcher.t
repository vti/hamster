use Test::More tests => 5;

use AnyEvent::XMPP::IM::Message;
use Hamster;
use Hamster::Dispatcher;
use Hamster::Command::Ping;

my $hamster = Hamster->new;

my $d = Hamster::Dispatcher->new(hamster => $hamster);
ok($d);

$d->add_map(qr/^PING$/ => Hamster::Command::Ping->new);

$d->dispatch(undef, undef, sub { ok(not defined shift) });

$d->dispatch(undef, _msg('FOO'), sub { ok(not defined shift); });

$d->dispatch(undef, _msg('PING'), sub { is(shift->body, 'PONG'); });

$d->add_map('*' => Hamster::Command::Ping->new);

$d->dispatch(undef, _msg('FOO'), sub { is(shift->body, 'PONG'); });

sub _msg {
    AnyEvent::XMPP::IM::Message->new(body => shift);
}

use Test::More tests => 2;

use Hamster;
use Hamster::Human;
use AnyEvent::XMPP::IM::Message;

use_ok('Hamster::Command::Stat');

my $cmd = Hamster::Command::Stat->new;
ok($cmd);

my $hamster = Hamster->new;

$cmd->hamster($hamster);

my $input = AnyEvent::XMPP::IM::Message->new(body => 'Hello');

my $msg =
  $cmd->run($input, sub { is(shift->body, "Topic 'Hello' was created"); });

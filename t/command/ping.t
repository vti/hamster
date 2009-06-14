use Test::More tests => 3;

use Hamster::Human;
use Hamster::Command::Ping;

my $cmd = Hamster::Command::Ping->new;
ok($cmd);

my $human = Hamster::Human->new(jid => 'foo@bar.com');

my $msg = $cmd->run(undef, $human, undef);

is($msg->to, 'foo@bar.com');
is($msg->body, 'PONG');

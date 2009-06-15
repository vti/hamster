use Test::More tests => 2;

use Hamster::Command::Ping;

my $cmd = Hamster::Command::Ping->new;
ok($cmd);

$cmd->run(undef, sub { is(shift->body, 'PONG'); });

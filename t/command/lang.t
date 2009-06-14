use strict;
use warnings;

use Test::More tests => 3;

use Hamster;
use Hamster::Human;
use Hamster::Command::Lang;

my $cmd = Hamster::Command::Lang->new;
ok($cmd);

my $human = Hamster::Human->new(jid => 'foo@bar.com');
my $hamster = Hamster->new;

my $msg = $cmd->run($hamster, $human, undef);
is($msg->to, 'foo@bar.com');
is($msg->body, 'en');

#$msg = $cmd->run(undef, $human, 'en');
#is($msg->to, 'foo@bar.com');
#is($msg->body, 'en');

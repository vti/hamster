use strict;
use warnings;

use Test::More tests => 2;

use Hamster;
use Hamster::Command::Lang;

my $hamster = Hamster->new;

my $cmd = Hamster::Command::Lang->new(hamster => $hamster);
ok($cmd);

$cmd->run(undef, sub { is(shift->body, 'en'); });

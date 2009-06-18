use strict;
use warnings;

use Test::More tests => 5;

use_ok('Hamster::Human');

my $human = Hamster::Human->new;
ok($human);

$human->add_jid(1, 'foo@bar.com');

is(@{$human->jids}, 1);

is($human->jids->[0]->jid, qw/foo@bar.com/);

is($human->jid('foo@bar.com/Hello')->id, 1);

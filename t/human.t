use strict;
use warnings;

use Test::More tests => 7;

use_ok('Hamster::Human');

my $human = Hamster::Human->new;

is("$human", "");

$human->jid('foo@bar.com');
is("$human", 'foo@bar.com');

$human->resource('BitlBee');
is("$human", 'foo@bar.com/BitlBee');

$human->parse('foo@bar.com');
is($human->jid, 'foo@bar.com');

$human->parse('foo@bar.com/BitlBee');
is($human->jid,      'foo@bar.com');
is($human->resource, 'BitlBee');

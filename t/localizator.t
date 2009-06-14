use strict;
use warnings;

use Test::More tests => 2;

use_ok('Hamster::Localizator');

my $i18n = Hamster::Localizator->new();

is($i18n->loc('foo'), 'foo');

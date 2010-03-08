
use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';
use Test::More tests => 3;
use MT::Test qw( :db );
use MT;

ok (MT->component ('geotype'), "Plugin loaded fine");

require MT::Entry;
ok (MT::Entry->has_column ('location_options'), "Added location_options column to entry table");
ok (MT::Entry->is_meta_column ('location_options'), "location_options is a meta column");

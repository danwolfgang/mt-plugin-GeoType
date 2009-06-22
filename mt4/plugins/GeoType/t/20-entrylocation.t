
use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';

use MT::Test qw( :db );

use Test::More tests => 1;

require GeoType::EntryLocation;
ok (MT::Object->driver->table_exists ('GeoType::EntryLocation'), "Table for GeoType::Location");

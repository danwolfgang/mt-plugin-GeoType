
use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';

use MT::Test qw( :db );

use Test::More tests => 1;

require GeoType::ExtendedLocation;
ok (MT::Object->driver->table_exists ('GeoType::ExtendedLocation'), "Table for GeoType::Location");

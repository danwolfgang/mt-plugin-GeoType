
use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';

use MT::Test qw( :db );

use Test::More tests => 1;

require GeoType::Location;
ok (MT::Object->driver->table_exists ('GeoType::Location'), "Table for GeoType::Location");

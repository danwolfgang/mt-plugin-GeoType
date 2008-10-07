
use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';

use MT;
use MT::Test qw( :db );

use Test::More tests => 6;

ok (MT->model ('asset.location'), "Model for asset.location");
ok (MT->model ('geotype_location_asset'), "Model for geotype_location_asset");

my $la = MT->model ('asset.location')->new;
ok ($la, "LocationAsset created");

$la->geometry ("1, 2");
is ($la->lattitude, 1, "Latitude");
is ($la->longitude, 2, "Longitude");
is ($la->geometry, "1,2", "Geometry");

use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';

use MT::Test qw( :db :data );
use Test::More tests => 3;
use Test::Deep;

use MT;
my $plugin = MT->component ('geotype');
$plugin->set_config_value ('google_api_key', 'abcdefg', 'blog:1');

require_ok ('GeoType::Util');
my $blog = MT::Blog->load ( 1 );
my @coords = GeoType::Util::geocode ($blog, "1600 Amphitheatre Parkway, Mountain View, CA");
is (int ($coords[0]), -122, "Latitude");
is (int ($coords[1]), 37, "Longitude");#], [ -122.085121,37.423088 ], "Geocoding Google!");

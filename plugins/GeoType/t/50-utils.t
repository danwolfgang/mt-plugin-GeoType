
use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';

use MT::Test qw( :db :data );
use Test::More tests => 2;
use Test::Deep;

use MT;
my $plugin = MT->component ('geotype');
$plugin->set_config_value ('google_api_key', 'abcdefg', 'blog:1');

require_ok ('GeoType::Util');
my $blog = MT::Blog->load ( 1 );
cmp_deeply ([GeoType::Util::geocode ($blog, "1600 Amphitheatre Parkway, Mountain View, CA")], [ -122.085121,37.423088 ], "Geocoding Google!");
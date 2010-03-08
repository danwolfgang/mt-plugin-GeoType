##########################################################################
# Copyright C 2007-2010 Six Apart Ltd.
# This program is free software: you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# version 2 for more details.  You should have received a copy of the GNU
# General Public License version 2 along with this program. If not, see
# <http://www.gnu.org/licenses/>.
# CMS.pm 20010-03-08  nataliepo

use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';

use MT::Test qw( :db :data );
use Test::More tests => 3;
use Test::Deep;

use MT;
my $plugin = MT->component('geotype');
$plugin->set_config_value( 'google_api_key', 'abcdefg', 'blog:1' );

require_ok('GeoType::Util');
my $blog   = MT::Blog->load(1);
my @coords = GeoType::Util::geocode( $blog,
    "1600 Amphitheatre Parkway, Mountain View, CA" );
is( int( $coords[0] ), -122, "Latitude" );
is( int( $coords[1] ), 37,   "Longitude" )
  ;    #], [ -122.085121,37.423088 ], "Geocoding Google!");

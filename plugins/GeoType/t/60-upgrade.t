##########################################################################
# Copyright C 2007-2010 Six Apart Ltd.
# This program is free software: you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# version 2 for more details. You should have received a copy of the GNU
# General Public License version 2 along with this program. If not, see
# <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';

use MT::Test qw( :db :data );
use Test::More tests => 24;
use Test::Deep;

require_ok('GeoType::Location');
require_ok('GeoType::EntryLocation');

my $loc = GeoType::Location->new;
$loc->blog_id(1);
$loc->name("Testing location");
$loc->location("Somewhere in testing land");
$loc->geometry("1, 4");
$loc->visible(1);

ok( $loc->save, "Saving test location" );

is( GeoType::Location->count, 1, "There should be only one location" );

my $entry_loc = GeoType::EntryLocation->new;
$entry_loc->blog_id(1);
$entry_loc->entry_id(1);
$entry_loc->location_id( $loc->id );

ok( $entry_loc->save, "Saving entry location" );

is( GeoType::EntryLocation->count, 1, "There should be only one entry location" );

require MT::Asset;
is( MT::Asset->count( { class => 'location' } ), 0, "There should be no assets" );

require_ok('GeoType::Upgrade');
&GeoType::Upgrade::location_to_asset();

is( MT::Asset->count( { class => 'location' } ), 1, "There should be one asset now" );
my $loc_asset = MT::Asset->load( { class => 'location' } );

ok( $loc_asset,                                "Asset loaded" );
ok( $loc_asset->isa('GeoType::LocationAsset'), "As the right class" );

is( $loc_asset->name,      "Testing location",          "Name upgraded correctly" );
is( $loc_asset->location,  "Somewhere in testing land", "Location upgraded correctly" );
is( $loc_asset->geometry,  "1,4",                       "Geometry ugpraded correctly" );
is( $loc_asset->latitude,  1,                           "Latitude correct" );
is( $loc_asset->longitude, 4,                           "Longitude correct" );
is( $loc_asset->blog_id,   1,                           "blog_id correct" );

require MT::ObjectAsset;
is( MT::ObjectAsset->count( { asset_id => $loc_asset->id } ), 1, "There should be one asset association" );
my $oa = MT::ObjectAsset->load( { asset_id => $loc_asset->id } );

ok( $oa, "ObjectAsset loaded" );
is( $oa->asset_id,  $loc_asset->id, "Has location asset id" );
is( $oa->object_ds, "entry",        "Entry datasource" );
is( $oa->object_id, 1,              "Entry #1" );
is( $oa->blog_id,   1,              "Blog #1" );
is( $oa->embedded,  0,              "Should not be embedded" );

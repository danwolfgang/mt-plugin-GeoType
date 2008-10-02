
use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';

use MT::Test qw( :db :data );
use Test::More tests => 1;
use Test::Exception;

require MT::Template::Context;
my $ctx = MT::Template::Context->new;

# # block tags
# ok ($ctx->handler_for ('GeoTypeLocations'), "GeoTypeLocations exists");
# ok ($ctx->handler_for ('GeoTypeIfLocation'), "GeoTypeIfLocation exists");
# ok ($ctx->handler_for ('GeoTypeIfLocationExtended'), "GeoTypeIfLocationExtended exists");
# 
# # function tags
# ok ($ctx->handler_for ('GeoTypeLocationName'), "GeoTypeLocationName exists");
# ok ($ctx->handler_for ('GeoTypeLocationId'), "GeoTypeLocationId exists");
# ok ($ctx->handler_for ('GeoTypeLocationGUID'), "GeoTypeLocationGUID exists");
# ok ($ctx->handler_for ('GeoTypeLocationLatitude'), "GeoTypeLocationLatitude exists");
# ok ($ctx->handler_for ('GeoTypeLocationLongitude'), "GeoTypeLocationLongitude, exists");
# ok ($ctx->handler_for ('GeoTypeLocationCrossStreet'), "GeoTypeLocationCrossStreet exists");
# ok ($ctx->handler_for ('GeoTypeLocationDescription'), "GeoTypeLocationDescription exists");
# ok ($ctx->handler_for ('GeoTypeLocationHours'), "GeoTypeLocationHours exists");
# ok ($ctx->handler_for ('GeoTypeLocationPhone'), "GeoTypeLocationPhone exists");
# ok ($ctx->handler_for ('GeoTypeLocationPlaceId'), "GeoTypeLocationPlaceId exists");
# ok ($ctx->handler_for ('GeoTypeLocationRating'), "GeoTypeLocationRating exists");
# ok ($ctx->handler_for ('GeoTypeLocationThumbnail'), "GeoTypeLocationThumbnail exists");
# ok ($ctx->handler_for ('GeoTypeLocationURL'), "GeoTypeLocationURL exists");
# ok ($ctx->handler_for ('GeoTypeCoords'), "GeoTypeCoords exists");
# ok ($ctx->handler_for ('GeoTypeLocation'), "GeoTypeLocation exists");
# ok ($ctx->handler_for ('GeoTypeMap'), "GeoTypeMap exists");
# ok ($ctx->handler_for ('GeoTypeHeader'), "GeoTypeHeader exists");
# ok ($ctx->handler_for ('GeoRSS_Namespace'), "GeoRSS_Namespace exists");
# ok ($ctx->handler_for ('GeoRSS_Channel'), "GeoRSS_Channel exists");
# ok ($ctx->handler_for ('GeoRSS_Entry'), "GeoRSS_Entry exists");

my @tags = keys %{$ctx->{__handlers}};
@tags = grep { /^geo/ } @tags;

use Data::Dumper;
print Dumper (\@tags);

ok ($ctx->handler_for ('geotype:entrymap'), 'GeoType:EntryMap exists');
package GeoType::ExtendedLocation;
use strict;

use base qw(MT::Object);

__PACKAGE__->install_properties({
	column_defs => {
                'id' => 'integer not null auto_increment',
                'location_id' => 'integer not null',
                'cross_street' => 'string(255)',
                'phone_number' => 'string(255)',
                'hours' => 'string(255)',
                'url' => 'string(255)',
                'thumbnail' => 'string(255)',
                'rating' => 'float',
                'description' => 'text',
                'place_id' => 'string(255)'
        },
    indexes => {
        location_id => 1
    },
    datasource => 'extendedlocation',
    primary_key => 'id'
});

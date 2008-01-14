package GeoType::ExtendedLocation;
use strict;
use GeoType::Location;

use base qw(MT::Object);

__PACKAGE__->install_properties({
	column_defs => {
	        'id' => 'integer not null auto_increment',
	        'location_id' => 'integer not null',
		'cross_street' => 'varchar(255)',
		'phone_number' => 'varchar(255)',
		'hours' => 'varchar(255)',
		'url' => 'varchar(255)',
		'thumbnail' => 'varchar(255)',
		'rating' => 'decimal',
		'description' => 'text',
		'place_id' => 'varchar(255)'
	},
    indexes => {
        location_id => 1
    },
    datasource => 'locationextended',
    primary_key => 'id',
    child_of    => 'GeoType::Location',
});

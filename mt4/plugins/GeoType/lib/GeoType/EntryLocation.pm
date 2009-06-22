package GeoType::EntryLocation;
use strict;

use base qw(MT::Object);

__PACKAGE__->install_properties({
	column_defs => {
	        'id' => 'integer not null auto_increment',
	        'blog_id' => 'integer not null',
	        'entry_id' => 'integer not null',
	        'location_id' => 'integer not null',
	        'zoom_level'    => 'smallint',
	},
    indexes => {
        entry_id => 1,
        blog_id => 1,
        location_id => 1
    },
    datasource => 'entrylocation',
    primary_key => 'id',
    child_of    => 'MT::Entry',
});

1;

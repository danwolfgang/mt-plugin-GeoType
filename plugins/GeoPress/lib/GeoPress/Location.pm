package GeoPress::Location;
use strict;

use GeoPress::EntryLocation;

use base qw(MT::Object);
@GeoPress::Location::ISA = qw( MT::Object );

__PACKAGE__->install_properties({
	column_defs => {
	        'id' => 'integer not null auto_increment',
	        'blog_id' => 'integer not null',
	        'name' => 'string(255)',
	        'location' => 'string(255)',
	        'mapurl' => 'string(255)',
	        'geometry' => 'text',
	        'visible' => 'integer not null default 1'
	},
    indexes => {
        name => 1,
        blog_id => 1
    },
    datasource => 'location',
    primary_key => 'id',
    
    child_classes => [ 'GeoPress::EntryLocation' ],
});

sub remove {
    my $location = shift;
    
    require MT::Request;
    my $r = MT::Request->instance;
    my @objs = GeoPress::EntryLocation->load ({ location_id => $location->id });
    $r->cache ('entry_location_objs', [ @objs ]);
    
    $location->remove_children ({ key => 'location_id' });
    $location->SUPER::remove (@_);
}

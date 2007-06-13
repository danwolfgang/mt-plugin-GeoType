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
});

sub get_location_for_entry {
	my $entry = shift;

	my $entry_location = GeoPress::EntryLocation->get_by_key({entry_id => $entry->id});
	my $location = GeoPress::Location->get_by_key({ id => $entry_location->location_id });		
    return $location;
}
sub entry_coords {
    my $ctx = shift;
    my $entry = $ctx->stash('entry');
    my $location = get_location_for_entry($entry);

    if ($location) {
        return $location->geometry;
    }
    return "";

}

sub entry_location {
    my $ctx = shift;
    my $entry = $ctx->stash('entry');
    my $location = get_location_for_entry($entry);

    if ($location) {
        return $location->location;
    }
    return "";
}

# sub geocode {
#     my ($operation, $config, $args) = @_;
#    
#     my $delay = $config->{'delay'};
#     if ($delay) { 
# 	debug("Sleeping for 1 second...");
# 	sleep(1); 
#     }
#     my $associateid = $config->{'associateid'};
#     my $accesskey   = $config->{'accesskey'};
#     my $locale      = $config->{'locale'};
# 
#     my $url = _compose_url($operation, $config, $args);
# 
#     debug("Getting $url");
#     require LWP::UserAgent;
#     require HTTP::Request;
#     my $ua = new LWP::UserAgent;
#     $ua->agent("MTAmazon/".$MT::Plugin::MTAmazon3::VERSION);
#     my $http_request = new HTTP::Request('GET', $url);
#     my $http_response = $ua->request($http_request);
#     my $content = $http_response->{'_content'};
#     # convert nodes that contain only spaces to empty nodes
#     $content =~ s/<[^\/]([^>]+)>\s+<\/[^>]+>/<$1 \/>/g; 
#     return $content;
# }
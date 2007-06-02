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

# sub get_all_locations {
# 	my $blog_id = shift;
# 
# 	my $locations = GeoPress::Location->load({ blog_id => $blog_id });
#   return $locations;
# }
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


sub save_location {
	my ($callback, $obj, $original) = @_;

	use MT::App;
	my $app = MT::App->instance;
	# my $entry_id = $app->{query}->param('id');
	my $blog_id = $original->blog_id;
	my $entry_id = $original->id;
	
	# no need to test if these already exist - get_by_key will create them if they don't
	my $entry_location = GeoPress::EntryLocation->get_by_key({entry_id => $entry_id, blog_id => $blog_id});

	# if( $entry_location ) {
	# 	$location = GeoPress::Location->new;
	# 	$entry_location = GeoPress::EntryLocation->new;
	# }
	# else {
	# }
	
	# my $location = GeoPress::Location->new;
	
  my $location_name = $app->{query}->param('locname');
  my $location_addr = $app->{query}->param('addr');
  my $geometry = $app->{query}->param('geometry');

	if($location_addr eq "") {
		return;
	}
	my $location = GeoPress::Location->get_by_key({ location => $location_addr});		
	$location->blog_id($blog_id);
	$location->location($location_addr);
	$location->name($location_name);
	$location->geometry($geometry);
	$location->visible(1);
	$location->save or die "Saving location failed: ", $location->errstr;
	  
	$entry_location->location_id($location->id);
	$entry_location->save or die "Saving entry_location failed: ", $entry_location->errstr;
	
	
	# 	my $xml = MTAmazon3::Util::CallAmazon("ListLookup",$app->{mmanager_cfg},{
	#     ListId        => $wishlist,
	#     ProductPage   => $current_page,
	#     ListType      => 'WishList',
	#     ResponseGroup => 'ListItems,ItemAttributes',
	# });
	# my $results = XMLin($xml);
	# 
	# if (my $msg = $results->{Lists}->{Request}->{Errors}->{Error}->{Message}) {
	#     $app->{message} = $msg;
	#     return search($app);
	# }	
	
	 # or
	#     return $callback->error("Error adding location: " . $location->errstr);
	#     };

	# Useful bits
	# $obj->blog_id;
	# $obj->text;
	# $obj->text($text);
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
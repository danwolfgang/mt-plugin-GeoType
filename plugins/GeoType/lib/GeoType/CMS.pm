
package GeoType::CMS;

use MT;
use GeoType::Util;

sub list_location {
	my ($app) = @_;
	
	my $plugin = MT->component ('geotype');
	
	$app->{breadcrumbs} = [];
	$app->add_breadcrumb ('GeoType: List Locations');
	my $offset = $app->param ('offset');
	$offset ||= 0;
	my ( $start_offset, $end_offset, $total_rows );
	$total_rows = GeoType::Location->count({ blog_id => $app->blog->id });
	if ( $offset > $total_rows ) {
		$offset = $total_rows - 20;
	}
	if ( $offset < 0 ) {
		$offset = 0;
	}
	$start_offset = $total_rows ? $offset + 1 : 0;
	$end_offset = ( $total_rows > $start_offset + 19 ) ? $start_offset + 19 : $total_rows;
	return $app->listing ({
		Type    => 'geotype_location',
		Offset  => $offset,
		Terms   => {
			blog_id => $app->blog->id
		},
		Args	=> {
			sort => 'name',
		},
		Code    => sub {
			my ($obj, $row) = @_;
			$row->{location_visible} = $obj->visible;
			$row->{location_id} = $obj->id;
			$row->{location_name} = $obj->name;
			$row->{location_address} = $obj->location;
			$row->{location_geometry} = $obj->geometry;
			
			require GeoType::EntryLocation;
			$row->{entries_count} = GeoType::EntryLocation->count ({ location_id => $obj->id });
			
		},
		Template    => $plugin->load_tmpl ('list_geotype_location.tmpl'),
		Params  => {
			offset		=> $offset,
			start_offset	=> $start_offset,
			prev_page	=> ( $start_offset > 20 ) ? $start_offset - 21 : 0,
			last_page	=> $total_rows - 20,
			end_offset	=> $end_offset,
			total_rows	=> $total_rows,
			forward_arrow	=> ( $end_offset < $total_rows) ? 1 : 0,
			back_arrow	=> ( $start_offset > 1 ) ? 1 : 0,
			quick_search    => 0,
			extensions      => $plugin->get_config_value ('use_extended_attributes', 'blog:'. $app->blog->id),
			google_api_key  => $plugin->get_google_api_key ($app->blog),
			map_height      => $plugin->get_config_value ('map_height', 'blog:'. $app->blog->id),
			map_width       => $plugin->get_config_value ('map_width', 'blog:' . $app->blog->id),
			default_zoom_level => $plugin->get_config_value ('default_zoom_level', 'blog:' . $app->blog->id),
			default_map_type => $plugin->get_config_value ('default_map_type', 'blog:' . $app->blog->id),
			map_width => $plugin->get_config_value ('map_width', 'blog:' . $app->blog->id),
			map_height => $plugin->get_config_value ('map_height', 'blog:' . $app->blog->id),

			map_controls_overview => $plugin->get_config_value ('map_controls_overview', 'blog:' . $app->blog->id),
			map_controls_scale => $plugin->get_config_value ('map_controls_scale', 'blog:' . $app->blog->id),
			map_controls_map_type => $plugin->get_config_value ('map_controls_map_type', 'blog:' . $app->blog->id),
			"map_controls_zoom_" .$plugin->get_config_value ('map_controls_zoom', 'blog:' . $app->blog->id) => 1,
			
			geotype_header  => geo_type_header_tag,
			
		},
	});
}

sub edit_extended_location {
	my ($app) = @_;
        my $param = { };
	my $plugin = MT->component ('geotype');

	my $blog_id = $app->param('blog_id');
	my $location_id = $app->param('location_id');
	$param->{blog_id} = $blog_id;
	$param->{location_id} = $location_id;

	( $location_id ) or die "Location ID not provided\n";
	# We need a location, but we may not have extended attributes
	my $location = GeoType::Location->load( $location_id );
	( $location ) or die "Cannot load location ID $location_id\n";
	my ( $extended ) = GeoType::ExtendedLocation->load({ location_id => $location_id });
	if ( $app->param('dosave') ) {
		$app->param('name') && $location->name($app->param('name'));
		$extended = GeoType::ExtendedLocation->new unless ( $extended );
		$extended->location_id($location_id);
		$extended->cross_street($app->param('cross_street'));
		$extended->description($app->param('description'));
		$extended->hours($app->param('hours'));
		$extended->phone_number($app->param('phone_number'));
		$extended->place_id($app->param('place_id'));
		my $rating = $app->param('rating');
		$rating = "" unless ( $rating eq $rating + 0 );
		$extended->rating($rating);
		$extended->thumbnail($app->param('thumbnail'));
		$extended->url($app->param('url'));
		$location->save;
		$extended->save;
	}

	$param->{loc_name} = $location->name;
	if ( $extended ) {
		$param->{loc_description} = $extended->description;
		$param->{loc_cross_street} = $extended->cross_street;
		$param->{loc_hours} = $extended->hours;
		$param->{loc_phone_number} = $extended->phone_number;
		$param->{loc_place_id} = $extended->place_id;
		$param->{loc_rating} = $extended->rating;
		$param->{loc_thumbnail} = $extended->thumbnail;
		$param->{loc_url} = $extended->url;
	}
	$app->{breadcrumbs} = [];
	$app->add_breadcrumb('Edit Location');
	$param->{script_url} = MT::ConfigMgr->instance->CGIPath . MT::ConfigMgr->instance->AdminScript;
	if ( $app->param('return_to_entry') ) {
		$param->{return_entry} = $app->param('return_to_entry');
	}
	my $tmpl = $plugin->load_tmpl("geotype_edit_extended.tmpl");
        $app->build_page($tmpl, $param);
	$app->build_page($tmpl);
}

sub create_location {
    my $app = shift;
    
    $app->load_tmpl ('dialog/create_location.tmpl');
}

sub verify_location {
    my $app = shift;
    
    my $address = $app->param ('location_address');
    my @coords  = GeoType::Util::geocode ($app->blog, $address);
    
    require GeoType::LocationAsset;
    my $la = GeoType::LocationAsset->new;
    $la->blog_id ($app->blog->id);
    $la->lattitude ($coords[1]);
    $la->longitude ($coords[0]);
    
    my $url = $la->thumbnail_url (Width => 600, Height => int(600 / 1.61));
    
    $app->load_tmpl ('dialog/verify_location.tmpl', { 
        location_address => $address,
        gecoded_url => $url,
        location_lattitude => $coords[1],
        location_longitude => $coords[0],
    });
}

sub insert_location {
    my $app = shift;
    my $address = $app->param ('location_address');
    my $name    = $app->param ('location_name');
    my $lattitude = $app->param ('location_lattitude');
    my $longitude = $app->param ('location_longitude');
    
    require GeoType::LocationAsset;
    my $la = GeoType::LocationAsset->new;
    $la->blog_id ($app->blog->id);
    $la->name ($name);
    $la->location ($address);
    $la->lattitude ($lattitude);
    $la->longitude ($longitude);
    
    $la->save or die $la->errstr;
    
    return $app->redirect(
        $app->uri(
            'mode' => 'list_assets',
            args   => { 'blog_id' => $app->param('blog_id') }
        )
    );
}

sub source_asset_options {
    my ($cb, $app, $tmpl) = @_;
    
    my $old = q{<__trans phrase="File Options">};
    my $new = q{<mt:unless name="asset_is_location"><__trans phrase="File Options"><mt:else>Location Options</mt:else></mt:unless>};
    
    $$tmpl =~ s/\Q$old\E/$new/;
}

sub param_asset_options {
    my ($cb, $app, $param, $tmpl) = @_;
    
    my $asset_id = $param->{asset_id};
    
    require MT::Asset;
    my $asset = MT::Asset->load ($asset_id);
    $param->{asset_is_location} = $asset->isa ('GeoType::LocationAsset');
}


1;

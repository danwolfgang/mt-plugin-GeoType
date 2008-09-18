
package GeoType::Tags;

sub geo_type_location_container {
    my $ctx = shift;
    my $res = '';
    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    my $entry = $ctx->stash('entry');
    my @locations;
    if ( ! $entry ) {                # Discover our context
        my $at = $ctx->{archive_type} || $ctx->{current_archive_type};
        if ( $at ) {
            @locations = get_locations_for_archive($ctx);
        } elsif ( $ctx->stash('locations') ) {
	    @locations = @{$ctx->stash('locations')};
	} else {
            return;
        }
    } else {
	@locations = get_locations_for_entry($entry);
    }
    foreach my $location ( @locations ) {
        $ctx->stash('geotype_location', $location);
	my @extended = GeoType::ExtendedLocation->load({ location_id => $location->id });
	my $extended;
	( scalar @extended > 0 ) && ( $extended = $extended[0] );
	if ( $extended ) {
		$ctx->stash('geotype_extended_location', $extended);
	} else {
		$ctx->stash('geotype_extended_location', 0 );
	}
        defined(my $out = $builder->build($ctx, $tokens))
            or return $ctx->error($builder->errstr);
        $res .= $out;
    }
    $res;
}

sub geo_type_if_location_extended {
    my $ctx = shift;
    if ( $ctx->stash('geotype_extended_location') && $ctx->stash('geotype_extended_location') ne '0' ) {
	return 1;
    } else {
        return 0;
    }
}

sub geo_type_name_tag {
	my $ctx = shift;
	my $location = $ctx->stash('geotype_location');
	return '' unless $location;
	return '' unless $location->id;
	return $location->name;
}

sub geo_type_id_tag {
	my $ctx = shift;
	my $location = $ctx->stash('geotype_location');
	return '' unless $location;
	return '' unless $location->id;
	return $location->id;
}

sub geo_type_GUID_tag {
	my $ctx = shift;
	my $location = $ctx->stash('geotype_location');
	return '' unless $location;
	return '' unless $location->id;
	return $location->make_guid;
}

sub geo_type_latitude_tag {
	my $ctx = shift;
	my $location = $ctx->stash('geotype_location');
	return '' unless $location;
	return '' unless $location->id;
	my $geometry = $location->geometry;
	return '' unless $location->geometry;
	my @coords = split(/, ?/, $geometry);
	return $coords[0];
}

sub geo_type_longitude_tag {
	my $ctx = shift;
	my $location = $ctx->stash('geotype_location');
	return '' unless $location;
	return '' unless $location->id;
	my $geometry = $location->geometry;
	return '' unless $location->geometry;
	my @coords = split(/, ?/, $geometry);
	return $coords[1];
}

sub geo_type_cross_street_tag {
	my $ctx = shift;
	my $extended = $ctx->stash('geotype_extended_location');
	return '' unless $extended;
	return '' unless $extended->id;
	return $extended->cross_street;
}

sub geo_type_hours_tag {
	my $ctx = shift;
	my $extended = $ctx->stash('geotype_extended_location');
	return '' unless $extended;
	return '' unless $extended->id;
	return $extended->hours;
}

sub geo_type_description_tag {
	my $ctx = shift;
	my $extended = $ctx->stash('geotype_extended_location');
	return '' unless $extended;
	return '' unless $extended->id;
	return $extended->description;
}

sub geo_type_phone_tag {
	my $ctx = shift;
	my $extended = $ctx->stash('geotype_extended_location');
	return '' unless $extended;
	return '' unless $extended->id;
	return $extended->phone_number;
}

sub geo_type_place_id_tag {
	my $ctx = shift;
	my $extended = $ctx->stash('geotype_extended_location');
	return '' unless $extended;
	return '' unless $extended->id;
	return $extended->place_id;
}

sub geo_type_rating_tag {
	my $ctx = shift;
	my $extended = $ctx->stash('geotype_extended_location');
	return '' unless $extended;
	return '' unless $extended->id;
	return $extended->rating;
}

sub geo_type_thumbnail_tag {
	my $ctx = shift;
	my $extended = $ctx->stash('geotype_extended_location');
	return '' unless $extended;
	return '' unless $extended->id;
	return $extended->thumbnail;
}

sub geo_type_URL_tag {
	my $ctx = shift;
	my $extended = $ctx->stash('geotype_extended_location');
	return '' unless $extended;
	return '' unless $extended->id;
	return $extended->url;
}

# Creates an actual map for an entry
sub geo_type_map_tag {
	my ($ctx, $args) = @_;
	my $entry = $ctx->stash('entry');
	my $entry_id;
	my $blog_id = $ctx->stash('blog_id');
	my @locations;
	my $zoom;
	my ($maxLat, $minLat, $maxLon, $minLon); # For archive maps w/no defined zoom

	if ( ! $entry ) {
		# Discover our context
		my $at = $ctx->{archive_type} || $ctx->{current_archive_type};
		if ( $at ) {
			@locations = get_locations_for_archive($ctx);
			($maxLat, $minLat, $maxLon, $minLon) = &get_bounds_for_locations(@locations);
			$entry_id = 'ARCH';
		} 
		elsif (my $n = $args->{lastnentries}) {
		    require MT::Entry;
            my @entries = MT::Entry->load ({ blog_id => $blog_id, status => MT::Entry::RELEASE() }, { sort => 'created_on', direction => 'descend', limit => $n });
            local $ctx->{__stash}{entries} = \@entries;
            @locations = get_locations_for_archive ($ctx);
		}
		else {
			# No entry, no archive
			return;
		}
	} else {
			@locations = get_locations_for_entry($entry);
			$zoom = get_zoom_for_entry ($entry);
			$entry_id = $entry->id;
	}

	my $config = $plugin->get_config_hash('blog:' . $blog_id);    

	our $useManager = 0;
	if (scalar @locations) {
		my $map_width  = $config->{map_width};
		my $map_height = $config->{map_height};
		my $html = qq@
			<div id="geo_map_$entry_id" style="width: ${map_width}px; height: ${map_height}px; float: left;"></div>
			<script type="text/javascript"> //<![CDATA[ 
			var geo_map_$entry_id;
		@;
		if ( scalar @locations > 10 ) {
			$html .= qq@
			var om = new OverlayMessage(document.getElementById('geo_map_${entry_id}'));
			om.Set('Please wait while data loads from Google Maps.');
			TC.attachLoadEvent (function() {
				        om.Clear();
			});
			@;
		}
		require MT::App;
		our $static_path;
		eval {
			$static_path = MT::App->instance->static_path;
		};
		if ( $@ ) {
			if ( $ctx->stash('static_uri') ) {
				$static_path = $ctx->stash('static_uri');
			} elsif ( MT::ConfigMgr->instance->StaticWebPath ) {
				$static_path = MT::ConfigMgr->instance->StaticWebPath;
			} else {
				die "Unable to locate STATIC_PATH";
			}
		}
		$html .= qq@
			TC.attachLoadEvent (function() {
				geo_map_$entry_id = new GMap2 (getByID ('geo_map_$entry_id'));
				geo_icon = new GIcon(G_DEFAULT_ICON)
				geo_icon.image = '${static_path}/plugins/GeoType/images/markericon.png';

		@;
		my $default_map_type   = $config->{default_map_type};
		if ( defined($maxLat) && defined($minLat) && defined($maxLon) && defined($minLon) ) {
			$html .= qq@
			var SW = new GLatLng($minLat, $minLon);
			var NE = new GLatLng($maxLat, $maxLon);
			var bounds = new GLatLngBounds( SW, NE );
			geo_map_$entry_id.setCenter(bounds.getCenter());
			geo_map_$entry_id.setZoom(geo_map_$entry_id.getBoundsZoomLevel(bounds));
			geo_map_$entry_id.setMapType($default_map_type);
			var marker_array_$entry_id = new Array();
			var cluster_$entry_id = new Clusterer(geo_map_${entry_id});
			clusterIcon = new GIcon(G_DEFAULT_ICON);
                        clusterIcon.image = '${static_path}/plugins/GeoType/images/clustermarker.png';
                        clusterIcon.shadow = '${static_path}/plugins/GeoType/images/clustershadow.png';
                        clusterIcon.iconSize = new GSize( 30, 51 );
                        clusterIcon.shadowSize = new GSize( 56, 51 );
                        clusterIcon.iconAnchor = new GPoint( 13, 34 );
                        clusterIcon.infoWindowAnchor = new GPoint( 13, 3 );
                        clusterIcon.iconShadowAnchor = new GPoint( 27, 37 );
                        cluster_ARCH.SetIcon( clusterIcon );
			cluster_${entry_id}.SetMaxVisibleMarkers( 20 );
			@;
			$useManager = 1;
		}
		
		require MT::Util;
		my $i = 1;
		my $default_zoom_level = $zoom || $config->{default_zoom_level};
		foreach my $location (@locations) {
			my $marker_html;
			my $marker_title;
			if ( $entry ) {
				$marker_title = $entry->title;
				$marker_title =~ s/'/\\'/g;
				$marker_html = $marker_title;
			} else {
				my @le = GeoType::EntryLocation->load({ location_id => $location->id });
				my $dummy_entry = MT::Entry->load( $le[0]->entry_id );
				
				$marker_title = $dummy_entry->title;
				$marker_title =~ s/'/\\'/g;
				my $entry_link = $dummy_entry->permalink;
				$marker_html = "<a href=\"$entry_link\">$marker_title</a>";
			}
			$marker_html = "<div class=\"GeoTypeMarkerContent\">$marker_html</div>";
			my $geom = $location->geometry;
			my $title_js = MT::Util::encode_js ($location->name);
			$html .= qq!
			var marker_$i = new GMarker (new GLatLng ($geom), { title: '$title_js', icon: geo_icon });
			GEvent.addListener(marker_$i, "click", function() { marker_$i.openInfoWindowHtml('$marker_html'); });
			!;
			if ( $useManager ) { 
			$html .= qq!
			cluster_${entry_id}.AddMarker(marker_$i, '$marker_title');
			!;
			} else {
			$html .= qq!
			geo_map_${entry_id}.setCenter (new GLatLng($geom), $default_zoom_level, $default_map_type);    
			geo_map_${entry_id}.addOverlay (marker_$i);
			!;
			}
			$i++;
		}
		
		$html .= qq{geo_map_$entry_id.addControl (new GOverviewMapControl());} if $plugin->get_config_value ('map_controls_overview', 'blog:' . $blog_id);
		$html .= qq{geo_map_$entry_id.addControl (new GScaleControl());} if $plugin->get_config_value ('map_controls_scale', 'blog:' . $blog_id);
		$html .= qq{geo_map_$entry_id.addControl (new GMapTypeControl());} if $plugin->get_config_value ('map_controls_map_type', 'blog:' . $blog_id);
		my $zoom = $plugin->get_config_value ('map_controls_zoom', 'blog:' . $blog_id);
		if ($zoom eq 'small') {
			$html .= qq{geo_map_$entry_id.addControl (new GSmallZoomControl());};
		}
		elsif ($zoom eq 'medium') {
			$html .= qq{geo_map_$entry_id.addControl (new GSmallMapControl());};
		}
		elsif ($zoom eq 'large') {
			$html .= qq{geo_map_$entry_id.addControl (new GLargeMapControl());};
		}
		$html .= qq!});
		// ]]> 
		</script>!;
		
		return $html;
	}
	return "";
}
		
sub geo_rss_namespace_tag {
	my $ctx = shift;
	my $blog_id = $ctx->stash('blog_id');
	my $config = $plugin->get_config_hash('blog:' . $blog_id);    

	my $georss_enable = $config->{georss_enable};        
	if ( ! $georss_enable ) {
		return "";
	}
	
	my $georss_format = $config->{georss_format};    
	if ($georss_format eq "simple") {
		return qq{ xmlns:georss="http://www.georss.org/georss"};
	}
	elsif ($georss_format eq "gml") {
		 return qq{ xmlns:georss="http://www.georss.org/georss" xmlns:gml="http://www.opengis.net/gml"};
	}
	elsif ($georss_format eq "w3c") {
		 return qq{ xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"};
	}
}    

sub geo_rss_channel_tag {
	my $ctx = shift;
	my $blog_id = $ctx->stash('blog_id');
	my $config = $plugin->get_config_hash('blog:' . $blog_id);    
	my $georss_format = $config->{georss_format};    

	my $georss_enable = $config->{georss_enable};        
	if( ! $georss_enable ) {
		return "";
	}
	
	return "";
}

sub geo_rss_entry_tag {
	my $ctx = shift;

	my $entry = $ctx->stash('entry');
	my $blog_id = $ctx->stash('blog_id');
        my $location = $ctx->stash('geotype_location');
        unless ( $location ) {
		( $location ) = get_locations_for_entry($entry);	
        }
	return "" unless ( $location );
        my $config = $plugin->get_config_hash('blog:' . $blog_id);    

	my $georss_enable = $config->{georss_enable};        
	if ( ! $georss_enable ) {
		return "";
	}
	
	my $georss_format = $config->{georss_format};    
	my $georss_entry;
	my $geometry = $location->geometry;

	if ($georss_format eq "simple") {
		 $georss_entry = qq{<georss:point>$geometry</georss:point>};
	}
	elsif ($georss_format eq "gml") {
		 $georss_entry =<<XML;
<georss:where>
	<gml:Point>
		<gml:pos>$geometry</gml:pos>
	</gml:Point>
</georss:where>
XML
	}
	elsif ($georss_format eq "w3c") {
		my @coords = split(/, ?/, $geometry);
		 $georss_entry = qq{<geo:lat>$coords[0]</geo:lat><geo:long>$coords[1]</geo:long>};
	}
	return $georss_entry;
}

# Tag to add the necessary mapping headers 
#TODO - figure out how to have this get included automatically
sub geo_type_header_tag {
	my ($ctx) = @_;
	
	my $blog;
	if ($ctx) {
		$blog = $ctx->stash ('blog');
	}
	else {
		require MT::App;
		$blog = MT::App->instance->blog;
	}
	
	my $google_api_key = $plugin->get_google_api_key ($blog, ($ctx ? 'site' : 'interface'));
	return "" if (!$google_api_key);
	
	require MT::App;
	my $static_path;
	eval {
		$static_path = MT::App->instance->static_path;
	};
	if ( $@ ) {
		if ( $ctx->stash('static_uri') ) {
			$static_path = $ctx->stash('static_uri');
		} elsif ( MT::ConfigMgr->instance->StaticWebPath ) {
			$static_path = MT::ConfigMgr->instance->StaticWebPath;
		} else {
			die "Unable to locate STATIC_PATH";
		}
	}
	my $html = qq{
		<script type="text/javascript" src="http://maps.google.com/maps?file=api&amp;v=2.s&amp;key=$google_api_key" ></script>
		<script type="text/javascript" src="${static_path}/plugins/GeoType/js/Clusterer2.js"></script>
		<script type="text/javascript" src="${static_path}/plugins/GeoType/js/OverlayMessage.js"></script>

		<style type="text/css">
			v\\:* {
			  behavior:url(#default#VML);
			}
		</style>
	};

	$html .= qq{
		<script type="text/javascript" src="${static_path}/js/core.js"></script>
		<script type="text/javascript" src="${static_path}/js/tc.js"></script>
		<script type="text/javascript" src="${static_path}/mt.js"></script>   
	} if (defined $ctx);
	
	return $html;    
}

1;
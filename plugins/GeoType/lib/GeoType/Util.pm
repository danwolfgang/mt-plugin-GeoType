package GeoType::Util;
use strict;

use Exporter;
@MT::Util::ISA = qw( Exporter );

use MT::Blog;
use MT::Util;

sub make_location_basename {
    my ($l) = @_;
    my $blog_id = $l->blog_id;
    my $blog = MT::Blog->load( $blog_id );
    $blog or die "Blog #$blog_id cannot be loaded.";
    my $location = $l->location; # "1600 Pennsylvania Ave NW, Washington DC", e.g.
    $location = '' if !defined $location;
    $location =~ s/^\s+|\s+$//gs;
    $location = 'location' if $location eq '';
    my $limit = $blog->basename_limit || 30; # FIXME
    $limit = 15 if $limit < 15; $limit = 250 if $limit > 250;
    my $base = substr(MT::Util::dirify($location), 0, $limit);
    $base =~ s/_+$//;
    $base = 'location' if $base eq '';
    my $i = 1;
    my $base_copy = $base;
    while (GeoType::Location->count({ blog_id => $blog->id,
                              basename => $base })) {
        $base = $base_copy . '_' . $i++;
    }
    $base;
}

sub get_google_api_key {
    my $plugin = MT->component ('geotype');
	my ($blog, $which) = @_;
	
	my $interface_api_key =  _get_api_key ($blog, 'google');
	my $site_api_key      =  $plugin->get_config_value ('site_api_key', 'blog:' . $blog->id) || $interface_api_key;
	
	return $which && $which eq 'site' ? $site_api_key : $interface_api_key;
}

sub _get_api_key {
    my $plugin = MT->component ('geotype');
	my ($blog, $key) = @_;
	
	my $system_value = $plugin->get_config_value ($key . '_api_key', 'system');
	my $blog_value   = $plugin->get_config_value ($key . '_api_key', 'blog:' . $blog->id);
	
	return $blog_value  ? $blog_value : $system_value ? $system_value : undef;
}

sub static_url_for_locations {
    my $plugin = MT->component ('geotype');
    my ($params, @locs) = @_;
    
    my $blog_id = $params->{blog_id} || $locs[0]->blog->id;
    require MT::Blog;
    my $blog = MT::Blog->load ($blog_id) or die "No blog_id: $blog_id";
    my $square = $params->{Square};
    if ($square) {
        if ($params->{Width} && !$params->{Height}) {
            $params->{Height} = $params->{Width};
        }
        elsif ($params->{Height} && !$params->{Width}) {
            $params->{Width} = $params->{Height};
        }
    }
    my $width  = $params->{Width} || $plugin->get_config_value ('static_map_width', 'blog:' . $blog_id);
    my $height = $params->{Height} || $plugin->get_config_value ('static_map_height', 'blog:' . $blog_id);
    
    my $key = get_google_api_key ($blog, 'interface');
    
    my $marker_str = $params->{marker_size} . $params->{marker_color};
    
    my $url = 'http://maps.google.com/staticmap?';
    $url .= "size=${width}x${height}";
    $url .= "&markers=" . join ("|", map { my $char = lc (delete $params->{marker_char}); join (',', $_->geometry, $marker_str . $char) } @locs);
    $url .= "&key=$key";
    
    $url .= "&maptype=" . ($params->{MapType} || $plugin->get_config_value ('static_map_type', 'blog:' . $blog_id));
    
    return wantarray ? ($url, $width, $height) : $url;
}

sub geocode {
    my $plugin = MT->component ('geotype');
    my ($blog, $address) = @_;
    
    my $key = get_google_api_key ($blog);
    my $url = 'http://maps.google.com/maps/geo?';
    
    require MT::Util;
    $url .= 'q=' . MT::Util::encode_url ($address);
    $url .= '&output=json';
    $url .= "&key=$key";
    
    my $ua = MT->new_ua;
    my $res = $ua->get ($url);

    # yeah, not pretty right now
    require JSON;
    my $obj = JSON::jsonToObj ($res->content);
    my $coords = $obj->{Placemark}->[0]->{Point}->{coordinates};
    return wantarray ? ($coords->[0], $coords->[1]) : join (',', $coords->[0], $coords->[1]);
}

sub asset_from_address {
    my $plugin = MT->component ('geotype');
    my ($blog, $address, $name) = @_;
    
    require GeoType::LocationAsset;
    my $la = GeoType::LocationAsset->new;
    $la->blog_id ($blog->id);
    $la->geometry (scalar geocode ($blog, $address));
    $la->location ($address);
    $la->name ($name) if ($name);
    
    return $la;
}

sub get_bounds_for_locations {
	my @locations = @_;
	my ( $maxLat, $minLat, $maxLon, $minLon );
	foreach my $location ( @locations ) {
		my ( $lat, $lon ) = split(/, ?/, $location->geometry );
		next unless ( $lat && $lon );
		$maxLat = $lat unless ( defined $maxLat );
		$minLat = $lat unless ( defined $minLat );
		$maxLon = $lon unless ( defined $maxLon );
		$minLon = $lon unless ( defined $minLon );
		( $lat > $maxLat ) && ( $maxLat = $lat );
		( $lat < $minLat ) && ( $minLat = $lat );
		( $lon > $maxLon ) && ( $maxLon = $lon );
		( $lon < $minLon ) && ( $minLon = $lon );
	}
	return ($maxLat, $minLat, $maxLon, $minLon);
}

1;
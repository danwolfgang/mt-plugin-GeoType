##########################################################################
# Copyright C 2007-2010 Six Apart Ltd.
# This program is free software: you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# version 2 for more details. You should have received a copy of the GNU
# General Public License version 2 along with this program. If not, see
# <http://www.gnu.org/licenses/>.

package GeoType::Tags;

use strict;
use warnings;

use GeoType::Util;

sub geo_type_location_container {
    my $ctx     = shift;
    my $res     = '';
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $entry   = $ctx->stash('entry');
    my @locations;
    if ( !$entry ) {    # Discover our context
        my $at = $ctx->{archive_type} || $ctx->{current_archive_type};
        if ($at) {
            @locations = get_locations_for_archive($ctx);
        }
        elsif ( $ctx->stash('locations') ) {
            @locations = @{ $ctx->stash('locations') };
        }
        else {
            return;
        }
    }
    else {
        @locations = get_locations_for_entry($entry);
    }
    foreach my $location (@locations) {
        $ctx->stash( 'geotype_location', $location );
        my @extended = GeoType::ExtendedLocation->load(
            { location_id => $location->id } );
        my $extended;
        ( scalar @extended > 0 ) && ( $extended = $extended[0] );
        if ($extended) {
            $ctx->stash( 'geotype_extended_location', $extended );
        }
        else {
            $ctx->stash( 'geotype_extended_location', 0 );
        }
        defined( my $out = $builder->build( $ctx, $tokens ) )
            or return $ctx->error( $builder->errstr );
        $res .= $out;
    }
    $res;
}

sub geo_type_if_location_extended {
    my $ctx = shift;
    if (   $ctx->stash('geotype_extended_location')
        && $ctx->stash('geotype_extended_location') ne '0' )
    {
        return 1;
    }
    else {
        return 0;
    }
}

sub _hdlr_location_name {
    return $_[0]->tag( 'assetlabel', $_[1], $_[2] );
}

sub _hdlr_location_description {
    return $_[0]->tag( 'assetdescription', $_[1], $_[2] );
}

sub _hdlr_location_latitude {
    my ( $ctx, $args, $cond ) = @_;
    my $asset = $ctx->stash('asset') or return $ctx->_no_asset_error();
    return '' unless ( $asset->isa('GeoType::LocationAsset') );
    return $asset->latitude ? $asset->latitude : '';
}

sub _hdlr_location_longitude {
    my ( $ctx, $args, $cond ) = @_;
    my $asset = $ctx->stash('asset') or return $ctx->_no_asset_error();
    return '' unless ( $asset->isa('GeoType::LocationAsset') );
    return $asset->longitude ? $asset->longitude : '';
}

sub _hdlr_location_thumbnail {
    return $_[0]->tag( 'assetthumbnailurl', $_[1], $_[2] );
}

sub _hdlr_locations {
    my ( $ctx, $args, $cond ) = @_;
    my $tag = lc $ctx->stash('tag');
    my $assets;
    if ( $tag eq 'entrylocations' ) {
        my $e = $ctx->stash('entry') or return $ctx->_no_entry_error();
        require MT::ObjectAsset;
        require MT::Asset;
        my @assets = MT::Asset->load(
            { class => 'location' },
            {
                join => MT::ObjectAsset->join_on(
                    undef,
                    {
                        asset_id  => \'= asset_id',
                        object_ds => 'entry',
                        object_id => $e->id
                    }
                )
            }
        );
        return '' unless @assets;
        $assets = \@assets;
    }
    local $ctx->{__stash}{assets} = $assets if ($assets);
    return $ctx->tag( 'assets', { %$args, class_type => 'asset.location' },
        $cond );
}

sub _hdlr_map_header {
    my ( $ctx, $args, $cond ) = @_;

    return '' if ( $ctx->var('geo_type_header') );

    my $blog = $ctx->stash('blog');

    $ctx->var( 'geo_type_header', 1 );
    my $key =
        GeoType::Util::get_google_api_key( $ctx->stash('blog'), 'site' );
    my $plugin = MT->component('geotype');
    my $config =
        $plugin->get_config_hash( 'blog:' . $ctx->stash('blog')->id );
    my $map_type = $config->{interactive_map_type};
    $map_type =
          $map_type eq 'roadmap'   ? 'G_NORMAL_MAP'
        : $map_type eq 'satellite' ? 'G_SATELLITE_MAP'
        : $map_type eq 'hybrid'    ? 'G_HYBRID_MAP'
        : $map_type eq 'terrain'   ? 'G_PHYSICAL_MAP'
        :                            'G_NORMAL_MAP';
    my $zoom          = $config->{interactive_map_zoom}         || 13;
    my $overview      = $config->{interactive_map_overview}     || 0;
    my $scale         = $config->{interactive_map_scale}        || 0;
    my $type          = $config->{interactive_map_type_control} || 0;
    my $zoom_controls = $config->{interactive_map_zoom_control} || 'none';
    my $static_path = $ctx->tag( 'StaticWebPath', {}, $cond );
    my $res = '';
    $res .= qq{
    <script type="text/javascript" src="${static_path}plugins/GeoType/js/Clusterer2.js"></script>
    <script type="text/javascript" src="${static_path}plugins/GeoType/js/OverlayMessage.js"></script>

    <script type="text/javascript" src="http://www.google.com/jsapi?key=$key"></script>
    <script type="text/javascript">


    var geo_type_maps = new Array();

    function is_map_div (elem) {
        return elem.getAttribute ('geotype:map');
    }

    function process_geo_type_map (elem) {

        /* grab the map id */
        var map_id = elem.getAttribute ('geotype:map');

        var markers = geo_type_maps[map_id].markers;
        /* first, setup the map itself */
        geo_type_maps[map_id].map = new google.maps.Map2 (elem);

        /* figure out the center */
        var center = geo_type_maps[map_id].center;
        if (!center) {
            var bounds = new google.maps.LatLngBounds();
            var locations = geo_type_maps[map_id].locations;
            for (var i = 0; i < locations.length; i++) {
                bounds.extend (new google.maps.LatLng (locations[i].lat, locations[i].lng));
            }
            center = bounds.getCenter();
        }
        else {
            center = new google.maps.LatLng (center[0], center[1]);
        }
        geo_type_maps[map_id].map.setCenter (center);

        /* figure out the map type */
        var map_type = geo_type_maps[map_id].map_type;
        if (!map_type) {
            map_type = $map_type;
        }
        geo_type_maps[map_id].map.setMapType (map_type);

        /* figure out the zoom */
        var zoom = geo_type_maps[map_id].zoom;
        if (!zoom) {
            zoom = $zoom;
        }
        geo_type_maps[map_id].map.setZoom(zoom);

        /* setup the controls */
        /* starting with overview */
        var overview = geo_type_maps[map_id].overview;
        if (overview == undefined) {
            overview = $overview;
        }

        if (overview) {
            geo_type_maps[map_id].map.addControl(new google.maps.OverviewMapControl());
        }

        /* the scale control */
        var scale = geo_type_maps[map_id].scale;
        if (scale == undefined) {
            scale = $scale;
        }

        if (scale) {
            geo_type_maps[map_id].map.addControl(new google.maps.ScaleControl());
        }

        /* map type control */
        var type = geo_type_maps[map_id].type;
        if (type == undefined) {
            type = $type;
        }

        if (type) {
            geo_type_maps[map_id].map.addControl(new google.maps.MapTypeControl());
        }

        var zoom_controls = geo_type_maps[map_id].zoom_controls;
        if (zoom_controls == undefined) {
            zoom_controls = '$zoom_controls';
        }

        if (zoom_controls) {
            switch (zoom_controls) {
                case 'none': break;
                case 'small_zoom': geo_type_maps[map_id].map.addControl(new google.maps.SmallZoomControl());
                                   break;
                case 'small': geo_type_maps[map_id].map.addControl(new google.maps.SmallMapControl());
                              break;
                case 'large': geo_type_maps[map_id].map.addControl(new google.maps.LargeMapControl());
                              break;
                default: break;
            }
        }

        var locations = geo_type_maps[map_id].locations;
        addLocationMarkers (geo_type_maps[map_id]);

        if (geo_type_maps[map_id].wikipedia) {
            geo_type_maps[map_id].map.addOverlay (new google.maps.Layer ("org.wikipedia." + geo_type_maps[map_id].wikipedia));
        }

        if (geo_type_maps[map_id].panoramio) {
            geo_type_maps[map_id].map.addOverlay (new google.maps.Layer ("com.panoramio.all"));
        }
    }

    function addLocationMarkers (geo_map) {
        geo_map.clusterer = new Clusterer(geo_map.map);
        /*clusterIcon = new GIcon(G_DEFAULT_ICON);
                            clusterIcon.image = '${static_path}/plugins/GeoType/images/clustermarker.png';
                            clusterIcon.shadow = '${static_path}/plugins/GeoType/images/clustershadow.png';
                            clusterIcon.iconSize = new GSize( 30, 51 );
                            clusterIcon.shadowSize = new GSize( 56, 51 );
                            clusterIcon.iconAnchor = new GPoint( 13, 34 );
                            clusterIcon.infoWindowAnchor = new GPoint( 13, 3 );
                            clusterIcon.iconShadowAnchor = new GPoint( 27, 37 );
                            cluster_ARCH.SetIcon( clusterIcon );*/
        geo_map.clusterer.SetMaxVisibleMarkers( 20 );

        var locations = geo_map.locations;
        for (var i = 0; i < locations.length; i++) {
            //map.addOverlay (markerForLocation (locations[i]));
            geo_map.clusterer.AddMarker (markerForLocation (locations[i]), locations[i].name);
        }
    }

    var letteredIcons = {};
    function markerForLocation (location) {

        var m = new google.maps.LatLng (location.lat, location.lng);
        var marker_options = { title: location.name };
        if (location.options) {
            var marker_char = location.options.marker_char;
            if (marker_char) {
                marker_char = marker_char.toUpperCase();
                if (!letteredIcons[marker_char]) {
                    letteredIcons[marker_char] = new google.maps.Icon (G_DEFAULT_ICON);
                    letteredIcons[marker_char].image = "http://www.google.com/mapfiles/marker" + marker_char + ".png";
                }

                marker_options['icon'] = letteredIcons[marker_char];
            }
        }

        var marker = new google.maps.Marker (m, marker_options);

        if (location.options && location.options.contents) {
            marker.bindInfoWindowHtml (location.options.contents);
        }

        return marker;
    }

    function maps_loaded () {
        var elems = document.getElementsByTagName('div');
        for (var i = 0; i < elems.length; i++) {
            if (is_map_div (elems[i])) {
                process_geo_type_map (elems[i]);
            }
        }
    }

    if(google)
        google.load ('maps', '2.x', { callback: maps_loaded });

    </script>
    };

    $res;
}

sub _locations_from_archive {
    my ($ctx);
}

sub _hdlr_map {
    my ( $ctx, $args, $cond ) = @_;

    my @assets;
    my @ids;
    my $blog_id = $ctx->stash('blog_id');
    my $map_id;
    my $loc_options = {};
    if ( $ctx->stash('tag') eq 'geotype:map' && $args->{lastnentries} ) {
        my $n = $args->{lastnentries};
        my ( %blog_terms, %blog_args );
        $ctx->set_blog_load_context( $args, \%blog_terms, \%blog_args )
            or return $ctx->error( $ctx->errstr );

        require MT::Entry;
        my @entries = MT::Entry->load(
            { %blog_terms, status => MT::Entry::RELEASE },
            {
                %blog_args,
                sort      => 'authored_on',
                direction => 'descend',
                limit     => $n
            }
        );
        $map_id = 'last-' . $n;
        push @ids, map { $_->id } @entries;

    }
    elsif ( $ctx->stash('tag') eq 'geotype:assetmap'
        || ( $ctx->stash('tag') eq 'geotype:map' && $ctx->stash('asset') ) )
    {
        my $asset = $ctx->stash('asset') or return $ctx->_no_asset_error();
        return '' unless ( $asset->isa('GeoType::LocationAsset') );

        $map_id = 'asset-' . $asset->id;
        push @assets, $asset;
        if ( my $e = $ctx->stash('entry') ) {
            $loc_options = $e->location_options;
        }
    }
    elsif ( $ctx->stash('tag') eq 'geotype:entrymap'
        || ( $ctx->stash('tag') eq 'geotype:map' && $ctx->stash('entry') ) )
    {
        my $e = $ctx->stash('entry') or return $ctx->_no_entry_error();
        push @ids, $e->id;

        $map_id      = 'entry-' . $e->id;
        $loc_options = $e->location_options;
    }
    elsif (
        $ctx->stash('tag') eq 'geotype:archivemap'
        || ( $ctx->stash('tag') eq 'geotype:map'
            && ( $ctx->{archive_type} || $ctx->{current_archive_type} ) )
        )
    {
        my $entries = $ctx->stash('entries') || [];
        push @ids, map { $_->id } @$entries;

        require MT::Util;
        my $title = $ctx->tag( 'archivetitle', {}, $cond );
        $title  = MT::Util::dirify($title);
        $map_id = 'archive-' . $title;
    }
    else {
        return $ctx->error('No context from which to extract locations');
    }

    require GeoType::LocationAsset;
    unless (@assets) {
        require MT::ObjectAsset;
        require MT::Asset;
        @assets = MT::Asset->load(
            { class => 'location' },
            {
                join => MT::ObjectAsset->join_on(
                    undef,
                    {
                        asset_id  => \'= asset_id',
                        object_ds => 'entry',
                        object_id => \@ids,
                        $args->{all} ? () : ( embedded => 0 )
                    }
                )
            }
        );
    }
    return '' unless @assets;

    my $width  = $args->{width};
    my $height = $args->{height};
    my $square = $args->{square};
    if ( $args->{static} ) {
        require GeoType::Util;
        my $params;
        $params->{Height} = $height if ($height);
        $params->{Width}  = $width  if ($width);

        $params->{Square}  = $square;
        $params->{blog_id} = $blog_id;

        my ( $url, $w, $h ) =
            GeoType::Util::static_url_for_locations( $params, @assets );
        return sprintf qq(<img src="%s" width="%d" height="%d" alt="" /></a>),
            $url, $w, $h;
    }
    else {
        require GeoType::Util;
        my $res = '';
        unless ( $ctx->var('google_maps_header') ) {
            $res .= $ctx->tag( 'geotype:mapheader', {}, {} );
        }
        my $plugin = MT->component('geotype');
        my $config = $plugin->get_config_hash( 'blog:' . $blog_id );
        $height = $config->{interactive_map_height} unless ($height);
        $width  = $config->{interactive_map_width}  unless ($width);
        my @locations = map {
            {
                id       => $_->id,
                name     => $_->name,
                geometry => $_->geometry,
                lat      => $_->latitude,
                lng      => $_->longitude,
                options  => $loc_options->{ $_->id }
            }
        } @assets;
        require JSON;
        my $location_json =
            @locations ? JSON::objToJson( \@locations ) : '[]';
        my $wikipedia = $args->{wikipedia} || '';
        my $panoramio = $args->{panoramio} || 0;
        $res .= qq{
            <div id='$map_id' geotype:map='$map_id' style="height: ${height}px; width: ${width}px"></div>

            <script type='text/javascript'>
                geo_type_maps["$map_id"] = new Object();
                geo_type_maps["$map_id"].locations = $location_json;
                geo_type_maps["$map_id"].wikipedia = '$wikipedia';
                geo_type_maps["$map_id"].panoramio = $panoramio;

                if(google)
                    google.load ('maps', '2.x', { callback: maps_loaded });
            </script>
        };
    }
}

sub geo_type_id_tag {
    my $ctx      = shift;
    my $location = $ctx->stash('geotype_location');
    return '' unless $location;
    return '' unless $location->id;
    return $location->id;
}

sub geo_type_GUID_tag {
    my $ctx      = shift;
    my $location = $ctx->stash('geotype_location');
    return '' unless $location;
    return '' unless $location->id;
    return $location->make_guid;
}

sub geo_type_latitude_tag {
    my $ctx      = shift;
    my $location = $ctx->stash('geotype_location');
    return '' unless $location;
    return '' unless $location->id;
    my $geometry = $location->geometry;
    return '' unless $location->geometry;
    my @coords = split( /, ?/, $geometry );
    return $coords[0];
}

sub geo_type_longitude_tag {
    my $ctx      = shift;
    my $location = $ctx->stash('geotype_location');
    return '' unless $location;
    return '' unless $location->id;
    my $geometry = $location->geometry;
    return '' unless $location->geometry;
    my @coords = split( /, ?/, $geometry );
    return $coords[1];
}

sub geo_type_cross_street_tag {
    my $ctx      = shift;
    my $extended = $ctx->stash('geotype_extended_location');
    return '' unless $extended;
    return '' unless $extended->id;
    return $extended->cross_street;
}

sub geo_type_hours_tag {
    my $ctx      = shift;
    my $extended = $ctx->stash('geotype_extended_location');
    return '' unless $extended;
    return '' unless $extended->id;
    return $extended->hours;
}

sub geo_type_description_tag {
    my $ctx      = shift;
    my $extended = $ctx->stash('geotype_extended_location');
    return '' unless $extended;
    return '' unless $extended->id;
    return $extended->description;
}

sub geo_type_phone_tag {
    my $ctx      = shift;
    my $extended = $ctx->stash('geotype_extended_location');
    return '' unless $extended;
    return '' unless $extended->id;
    return $extended->phone_number;
}

sub geo_type_place_id_tag {
    my $ctx      = shift;
    my $extended = $ctx->stash('geotype_extended_location');
    return '' unless $extended;
    return '' unless $extended->id;
    return $extended->place_id;
}

sub geo_type_rating_tag {
    my $ctx      = shift;
    my $extended = $ctx->stash('geotype_extended_location');
    return '' unless $extended;
    return '' unless $extended->id;
    return $extended->rating;
}

sub geo_type_thumbnail_tag {
    my $ctx      = shift;
    my $extended = $ctx->stash('geotype_extended_location');
    return '' unless $extended;
    return '' unless $extended->id;
    return $extended->thumbnail;
}

sub geo_type_URL_tag {
    my $ctx      = shift;
    my $extended = $ctx->stash('geotype_extended_location');
    return '' unless $extended;
    return '' unless $extended->id;
    return $extended->url;
}

# Creates an actual map for an entry
sub geo_type_map_tag {
    my ( $ctx, $args ) = @_;
    my $entry = $ctx->stash('entry');
    my $entry_id;
    my $blog_id = $ctx->stash('blog_id');
    my @locations;
    my $zoom;
    my ( $maxLat, $minLat, $maxLon, $minLon )
        ;    # For archive maps w/no defined zoom

    if ( !$entry ) {

        # Discover our context
        my $at = $ctx->{archive_type} || $ctx->{current_archive_type};
        if ($at) {
            @locations = get_locations_for_archive($ctx);
            ( $maxLat, $minLat, $maxLon, $minLon ) =
                &get_bounds_for_locations(@locations);
            $entry_id = 'ARCH';
        }
        elsif ( my $n = $args->{lastnentries} ) {
            require MT::Entry;
            my @entries = MT::Entry->load(
                { blog_id => $blog_id, status => MT::Entry::RELEASE() },
                { sort => 'created_on', direction => 'descend', limit => $n }
            );
            local $ctx->{__stash}{entries} = \@entries;
            @locations = get_locations_for_archive($ctx);
        }
        else {

            # No entry, no archive
            return;
        }
    }
    else {
        @locations = get_locations_for_entry($entry);
        $zoom      = get_zoom_for_entry($entry);
        $entry_id  = $entry->id;
    }
    my $plugin = MT->component('geotype');
    my $config = $plugin->get_config_hash( 'blog:' . $blog_id );

    our $useManager = 0;
    if ( scalar @locations ) {
        my $map_width  = $config->{map_width};
        my $map_height = $config->{map_height};
        my $html       = qq@
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
        eval { $static_path = MT::App->instance->static_path; };
        if ($@) {
            if ( $ctx->stash('static_uri') ) {
                $static_path = $ctx->stash('static_uri');
            }
            elsif ( MT::ConfigMgr->instance->StaticWebPath ) {
                $static_path = MT::ConfigMgr->instance->StaticWebPath;
            }
            else {
                die "Unable to locate STATIC_PATH";
            }
        }
        $html .= qq@
            TC.attachLoadEvent (function() {
                geo_map_$entry_id = new GMap2 (getByID ('geo_map_$entry_id'));
                geo_icon = new GIcon(G_DEFAULT_ICON)
                geo_icon.image = '${static_path}/plugins/GeoType/images/markericon.png';

        @;
        my $default_map_type = $config->{default_map_type};
        if (   defined($maxLat)
            && defined($minLat)
            && defined($maxLon)
            && defined($minLon) )
        {
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
            if ($entry) {
                $marker_title = $entry->title;
                $marker_title =~ s/'/\\'/g;
                $marker_html = $marker_title;
            }
            else {
                my @le = GeoType::EntryLocation->load(
                    { location_id => $location->id } );
                my $dummy_entry = MT::Entry->load( $le[0]->entry_id );

                $marker_title = $dummy_entry->title;
                $marker_title =~ s/'/\\'/g;
                my $entry_link = $dummy_entry->permalink;
                $marker_html = "<a href=\"$entry_link\">$marker_title</a>";
            }
            $marker_html =
                "<div class=\"GeoTypeMarkerContent\">$marker_html</div>";
            my $geom     = $location->geometry;
            my $title_js = MT::Util::encode_js( $location->name );
            $html .= qq!
            var marker_$i = new GMarker (new GLatLng ($geom), { title: '$title_js', icon: geo_icon });
            GEvent.addListener(marker_$i, "click", function() { marker_$i.openInfoWindowHtml('$marker_html'); });
            !;
            if ($useManager) {
                $html .= qq!
            cluster_${entry_id}.AddMarker(marker_$i, '$marker_title');
            !;
            }
            else {
                $html .= qq!
            geo_map_${entry_id}.setCenter (new GLatLng($geom), $default_zoom_level, $default_map_type);
            geo_map_${entry_id}.addOverlay (marker_$i);
            !;
            }
            $i++;
        }

        $html .= qq{geo_map_$entry_id.addControl (new GOverviewMapControl());}
            if $plugin->get_config_value( 'map_controls_overview',
            'blog:' . $blog_id );
        $html .= qq{geo_map_$entry_id.addControl (new GScaleControl());}
            if $plugin->get_config_value( 'map_controls_scale',
            'blog:' . $blog_id );
        $html .= qq{geo_map_$entry_id.addControl (new GMapTypeControl());}
            if $plugin->get_config_value( 'map_controls_map_type',
            'blog:' . $blog_id );
        my $zoom = $plugin->get_config_value( 'map_controls_zoom',
            'blog:' . $blog_id );
        if ( $zoom eq 'small' ) {
            $html .=
                qq{geo_map_$entry_id.addControl (new GSmallZoomControl());};
        }
        elsif ( $zoom eq 'medium' ) {
            $html .=
                qq{geo_map_$entry_id.addControl (new GSmallMapControl());};
        }
        elsif ( $zoom eq 'large' ) {
            $html .=
                qq{geo_map_$entry_id.addControl (new GLargeMapControl());};
        }
        $html .= qq!});
        // ]]>
        </script>!;

        return $html;
    }
    return "";
}

# sub geo_rss_namespace_tag {
#   my $ctx = shift;
#   my $blog_id = $ctx->stash('blog_id');
#   my $config = $plugin->get_config_hash('blog:' . $blog_id);
#
#   my $georss_enable = $config->{georss_enable};
#   if ( ! $georss_enable ) {
#       return "";
#   }
#
#   my $georss_format = $config->{georss_format};
#   if ($georss_format eq "simple") {
#       return qq{ xmlns:georss="http://www.georss.org/georss"};
#   }
#   elsif ($georss_format eq "gml") {
#        return qq{ xmlns:georss="http://www.georss.org/georss" xmlns:gml="http://www.opengis.net/gml"};
#   }
#   elsif ($georss_format eq "w3c") {
#        return qq{ xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"};
#   }
# }
#
# sub geo_rss_channel_tag {
#   my $ctx = shift;
#   my $blog_id = $ctx->stash('blog_id');
#   my $config = $plugin->get_config_hash('blog:' . $blog_id);
#   my $georss_format = $config->{georss_format};
#
#   my $georss_enable = $config->{georss_enable};
#   if( ! $georss_enable ) {
#       return "";
#   }
#
#   return "";
# }
#
# sub geo_rss_entry_tag {
#   my $ctx = shift;
#
#   my $entry = $ctx->stash('entry');
#   my $blog_id = $ctx->stash('blog_id');
#         my $location = $ctx->stash('geotype_location');
#         unless ( $location ) {
#       ( $location ) = get_locations_for_entry($entry);
#         }
#   return "" unless ( $location );
#         my $config = $plugin->get_config_hash('blog:' . $blog_id);
#
#   my $georss_enable = $config->{georss_enable};
#   if ( ! $georss_enable ) {
#       return "";
#   }
#
#   my $georss_format = $config->{georss_format};
#   my $georss_entry;
#   my $geometry = $location->geometry;
#
#   if ($georss_format eq "simple") {
#        $georss_entry = qq{<georss:point>$geometry</georss:point>};
#   }
#   elsif ($georss_format eq "gml") {
#        $georss_entry =<<XML;
# <georss:where>
#   <gml:Point>
#       <gml:pos>$geometry</gml:pos>
#   </gml:Point>
# </georss:where>
# XML
#   }
#   elsif ($georss_format eq "w3c") {
#       my @coords = split(/, ?/, $geometry);
#        $georss_entry = qq{<geo:lat>$coords[0]</geo:lat><geo:long>$coords[1]</geo:long>};
#   }
#   return $georss_entry;
# }
#
# # Tag to add the necessary mapping headers
# #TODO - figure out how to have this get included automatically
# sub geo_type_header_tag {
#   my ($ctx) = @_;
#
#   my $blog;
#   if ($ctx) {
#       $blog = $ctx->stash ('blog');
#   }
#   else {
#       require MT::App;
#       $blog = MT::App->instance->blog;
#   }
#
#   my $google_api_key = $plugin->get_google_api_key ($blog, ($ctx ? 'site' : 'interface'));
#   return "" if (!$google_api_key);
#
#   require MT::App;
#   my $static_path;
#   eval {
#       $static_path = MT::App->instance->static_path;
#   };
#   if ( $@ ) {
#       if ( $ctx->stash('static_uri') ) {
#           $static_path = $ctx->stash('static_uri');
#       } elsif ( MT::ConfigMgr->instance->StaticWebPath ) {
#           $static_path = MT::ConfigMgr->instance->StaticWebPath;
#       } else {
#           die "Unable to locate STATIC_PATH";
#       }
#   }
#   my $html = qq{
#       <script type="text/javascript" src="http://maps.google.com/maps?file=api&amp;v=2.s&amp;key=$google_api_key" ></script>
#       <script type="text/javascript" src="${static_path}/plugins/GeoType/js/Clusterer2.js"></script>
#       <script type="text/javascript" src="${static_path}/plugins/GeoType/js/OverlayMessage.js"></script>
#
#       <style type="text/css">
#           v\\:* {
#             behavior:url(#default#VML);
#           }
#       </style>
#   };
#
#   $html .= qq{
#       <script type="text/javascript" src="${static_path}/js/core.js"></script>
#       <script type="text/javascript" src="${static_path}/js/tc.js"></script>
#       <script type="text/javascript" src="${static_path}/mt.js"></script>
#   } if (defined $ctx);
#
#   return $html;
# }

1;

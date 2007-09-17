#-------------------------------------------------------------------------------
#
#  Copyright (c) 2007 HighEarthOrbit
#
#   This file is part of the GeoPress
#   http://georss.org/geopress
#
#  Author   : Andrew Turner
#  Version  : 1
#  Location : 
#
#  Abstract : 
#
#   A MovableType plugin to enable adding geographic data (points,lines,areas) to 
#	blog posts, adding maps, outputing GeoRSS and KML feeds
#
#
#  Copyright notice:
#
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License  
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#  
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of 
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
#   GNU General Public License for more details.
#  
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#-------------------------------------------------------------------------------
#

package MT::Plugin::GeoType; 
use base qw(MT::Plugin);
use strict;
use warnings;

use MT;
use GeoType::Location;
use GeoType::EntryLocation;

use Data::Dumper;

use vars qw( $VERSION );
$VERSION = 1.3; 

my $plugin = MT::Plugin::GeoType->new ({
    name        => "GeoType",
	key         => "GeoType",
    version     => $VERSION,
    description => "<MT_TRANS phrase=\"GeoType allows you to specify the location for any blog post and inserting maps, coordinates, location names in the post. You can also add GeoRSS to your RSS or Atom syndication feeds, and KML to visualize blog post locations in GoogleEarth.<br\><br\>GeoType settings are on a per-blog setting, so you'll need to set this up in each weblog you administer. Use the 'GeoType' link in the left sidebar under 'Utilities' to configure your Map defaults and Locations.\">",
    author_name => "Apperceptive, LLC",
    author_link => "http://apperceptive.com/",

	schema_version => 1.1,
 	object_classes => [ 'GeoType::Location', 'GeoType::EntryLocation' ],
	
	system_config_template  => 'config.tmpl',
	blog_config_template    => 'blog_config.tmpl',
    settings        => MT::PluginSettings->new ([
        [ 'google_api_key', 	    { Default => 'GOOGLE_API_KEY',  Scope => 'system' } ],
        [ 'google_api_key', 	    { Default => 'GOOGLE_API_KEY',  Scope => 'blog' } ],
        [ 'site_api_key',           { Default => '',                Scope => 'blog' } ],
        [ 'georss_format', 	        { Default => 'simple',          Scope => 'blog' } ],
        [ 'georss_enable', 	        { Default => 1,                 Scope => 'blog' } ],
        [ 'map_width', 		        { Default => '200',             Scope => 'blog' } ],
        [ 'map_height', 		    { Default => '200',             Scope => 'blog' } ],
        [ 'default_map_type', 		{ Default => 'G_HYBRID_MAP',    Scope => 'blog' } ],
        [ 'map_controls_pan', 		{ Default => 1,                 Scope => 'blog' } ],
        [ 'map_controls_map_type',  { Default => 1,                 Scope => 'blog' } ],
        [ 'map_controls_zoom', 		{ Default => "small",           Scope => 'blog' } ],
        [ 'map_controls_overview',  { Default => 0,                 Scope => 'blog' } ],
        [ 'map_controls_scale', 	{ Default => 1,                 Scope => 'blog' } ],
        [ 'default_add_map', 		{ Default => 'all',             Scope => 'blog' } ],
        [ 'default_zoom_level', 	{ Default => 11,                Scope => 'blog' } ],
	]),
	
	callbacks    => {
			'MT::App::CMS::AppTemplateSource.edit_entry' => \&_edit_entry,
            'MT::App::CMS::AppTemplateSource.blog-left-nav' => \&left_nav,
            'CMSPostSave.entry' => \&post_save_entry,
            
            'CMSPostDelete.geotype_location'   => \&post_delete_location,
	},
	
	template_tags => {
			'GeoTypeCoords' => \&geo_type_coords_tag,
			'GeoTypeLocation' => \&geo_type_location_tag,
			'GeoTypeMap' => \&geo_type_map_tag,
			'GeoTypeHeader' =>\&geo_type_header_tag,
			'GeoRSS_Namespace' =>\&geo_rss_namespace_tag,
			'GeoRSS_Channel' =>\&geo_rss_channel_tag,
			'GeoRSS_Entry' =>\&geo_rss_entry_tag,
	},
	
	conditional_tags    => {
	        'GeoTypeIfLocation'  => \&geo_type_if_location_tag,
	},
	
	app_methods => {
	   'MT::App::CMS'  => {
	       'geotype_list_locations'  => \&list_locations,
	   },
	},
	
    app_itemset_actions => {
        'MT::App::CMS'  => [
            map {
                { type    => 'geotype_locations', %{$_}, },
                { type    => 'geotype_location', %{$_}, }
            } (
                {
                    key => 'geotype_location_visible',
                    label   => 'Make location(s) vislble',
                    code    => \&visible_locations,
                },
                {
                    key => 'geotype_locations_invisible',
                    label   => 'Make location(s) not visible',
                    code    => \&invisible_locations,
                }
            ),
        ],
    },
    
    init_app    => {
        'MT::App::CMS'  => \&init_cms,
    }
});

MT->add_plugin($plugin);

sub visible_locations {
    my $app = shift;
    my @ids = $app->param ('id');
    require GeoType::Location;
    map {
        my $loc = GeoType::Location->load ($_);
        $loc->visible (1);
        $loc->save or return $app->error ("Error saving location: " . $loc->errstr);
    } @ids;
    
    $app->call_return;
}

sub invisible_locations {
    my $app = shift;
    my @ids = $app->param ('id');
    require GeoType::Location;
    map {
        my $loc = GeoType::Location->load ($_);
        $loc->visible (0);
        $loc->save or return $app->error ("Error saving location: " . $loc->errstr);
    } @ids;
    
    $app->call_return;    
}

sub post_delete_location {
    my ($cb, $app, $obj) = @_;
    
    require MT::Request;
    my $r = MT::Request->instance;
    my $entry_locations = $r->cache ('entry_location_objs') || [];

    $app->rebuild_entry (Entry => $_->entry_id, BuildDependencies => 1) foreach (@$entry_locations);
}


sub instance { $plugin; }
	
sub left_nav {
    my ($eh, $app, $tmpl) = @_;
    my $slug = <<END_TMPL;
<li><a style="background-image: url(<TMPL_VAR NAME=STATIC_URI>images/nav_icons/color/plugins.gif);" <TMPL_IF NAME=NAV_MEDIAMANAGER>class="here"</TMPL_IF> id="nav-mmanager" title="<MT_TRANS phrase="GeoType">" href="<TMPL_VAR NAME=MT_URL>?__mode=geotype_list_locations&amp;blog_id=<TMPL_VAR NAME=BLOG_ID>"><MT_TRANS phrase="GeoType"></a></li>
END_TMPL
    $$tmpl =~ s/(<li><MT_TRANS phrase=\"Utilities\">\n<ul class=\"sub\">)/$1$slug/;
}

sub init_cms {
    my $plugin = shift;
    my $app = shift;
    $app->register_type ('geotype_location', 'GeoType::Location');
}


# Creates an actual map for an entry
sub geo_type_map_tag {
	my $ctx = shift;
	my $entry = $ctx->stash('entry');
	my $blog_id = $ctx->stash('blog_id');
	
	my @locations = get_locations_for_entry($entry);
	
	my $zoom = get_zoom_for_entry ($entry);

 	my $config = $plugin->get_config_hash('blog:' . $blog_id);	

	if (scalar @locations) {
	    my $entry_id   = $entry->id;
	    my $map_width  = $config->{map_width};
	    my $map_height = $config->{map_height};
	    my $html = qq@
	        <div id="geo_map_$entry_id" style="width: ${map_width}px; height: ${map_height}px; float: left;"></div>
            <script type="text/javascript"> //<![CDATA[ 
            var geo_map_$entry_id;
            TC.attachLoadEvent (function() {
                geo_map_$entry_id = new GMap2 (getByID ('geo_map_$entry_id'));
            
	    @;
	    
	    require MT::Util;
	    my $i = 1;
	    my $default_zoom_level = $zoom || $config->{default_zoom_level};
	    my $default_map_type   = $config->{default_map_type};
	    foreach my $location (@locations) {
	        my $geom = $location->geometry;
	        my $title_js = MT::Util::encode_js ($location->name);
	        $html .= qq!
            var marker_$i = new GMarker (new GLatLng ($geom), { title: '$title_js' });

            geo_map_${entry_id}.setCenter (new GLatLng($geom), $default_zoom_level, $default_map_type);    
            geo_map_${entry_id}.addOverlay (marker_$i);
            !;
            $i++;
	    }
	    
	    $html .= qq{geo_map_$entry_id.addControl (new GOverviewMapControl());} if $plugin->get_config_value ('map_controls_overview', 'blog:' . $blog_id);
        $html .= qq{geo_map_$entry_id.addControl (new GScaleControl());} if $plugin->get_config_value ('map_controls_scale', 'blog:' . $blog_id);
        $html .= qq{geo_map_$entry_id.addControl (new GMapTypeControl());} if $plugin->get_config_value ('map_controls_map_type', 'blog:' . $blog_id);
        my $zoom - $plugin->get_config_value ('map_controls_zoom', 'blog:' . $blog_id);
        $zoom eq 'small'    ? $html .= qq{geo_map_$entry_id.addControl (new GSmallZoomControl());} :
        $zoom eq 'medium'   ? $html .= qq{geo_map_$entry_id.addControl (new GSmallMapControl());}  :
        $zoom eq 'large'    ? $html .- qq{geo_map_$entry_id.addControl (new GLargeMapControl());}  : 0;
	    
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
	my $location = get_locations_for_entry($entry);
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
		my @coords = split(/,/, $geometry);
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
    my $static_path = MT::App->instance->static_path;
    my $html = qq{
        <script type='text/javascript' src='http://maps.google.com/maps?file=api&amp;v=2&amp;key=$google_api_key' ></script>
        <style type="text/css">
            v\\:* {
              behavior:url(#default#VML);
            }
        </style>
    };

    $html .= qq{
        <script type="text/javascript" src="${static_path}js/tc.js"></script>
        <script type="text/javascript" src="${static_path}mt.js"></script>   
    } if (defined $ctx);
    
    return $html;    
}

# Creates the Edit form when writing an entry
sub _edit_entry {
    my ($cb, $app, $tmpl) = @_;
	my $blog = $app->blog;
    my $config = $plugin->get_config_hash('system');
	my $google_api_key = $plugin->get_google_api_key ($blog);
	
	my ($old, $new);
	$old = qq{<TMPL_IF NAME=DISP_PREFS_SHOW_EXCERPT>};
		
	if ($google_api_key) {
	    my $zoom_level = $plugin->get_config_value ('default_zoom_level', 'blog:' . $blog->id);
		my $entry_id = $app->param('id');
		my @entry_locations = GeoType::EntryLocation->load ({ entry_id => $entry_id });
		
		my @location_loop;
		foreach my $id (0 .. $#entry_locations) {
		    my $location;
		    $location = GeoType::Location->load ($entry_locations[$id]->location_id) if ($entry_locations[$id]);
		    if ($location) {
                $zoom_level = $entry_locations[$id]->zoom_level if ($entry_locations[$id]->zoom_level);
		        push @location_loop, {
		            location_ord    => $id + 1,
		            location_id     => $entry_locations[$id]->id,
		            location_name   => $location->name,
		            location_addr   => $location->location,
		            location_geometry   => $location->geometry,
		        };
		    }
		    else {
		        push @location_loop, {
		            location_ord    => $id + 1,
		        };
		    }
		    
		}
		
		my $header = geo_type_header_tag;
		my $tmpl = $plugin->load_tmpl("geotype_edit.tmpl") or die "Error loading template: ", $plugin->errstr;
		$tmpl->param ( location_num => $#location_loop, location_loop => \@location_loop );

		my @locations = grep { $_->visible } GeoType::Location->load ({ blog_id => $blog->id });
		$tmpl->param ( saved_locations_loop => [ map { { location_value => $_->location, location_name => $_->name } } @locations ] );

		$tmpl->param ( default_zoom_level => $zoom_level );
		$tmpl->param ( default_map_type => $plugin->get_config_value ('default_map_type', 'blog:' . $blog->id) );
		$tmpl->param ( map_width => $plugin->get_config_value ('map_width', 'blog:' . $blog->id) );
		$tmpl->param ( map_height => $plugin->get_config_value ('map_height', 'blog:' . $blog->id) );
		
        $tmpl->param ( map_controls_overview => $plugin->get_config_value ('map_controls_overview', 'blog:' . $blog->id) );
        $tmpl->param ( map_controls_scale => $plugin->get_config_value ('map_controls_scale', 'blog:' . $blog->id) );
        $tmpl->param ( map_controls_map_type => $plugin->get_config_value ('map_controls_map_type', 'blog:' . $blog->id) );
        
        my $zoom = $plugin->get_config_value ('map_controls_zoom', 'blog:' . $blog->id);
        $tmpl->param ( "map_controls_zoom_$zoom" => 1 );
		
		$new = $header.($tmpl->output);
	} else {
		$new = "<p>To Enable GeoType, add the appropriate mapping library keys in your settings.</p>";
	}
	$$tmpl =~ s/\Q$old\E/$new\n$old\n/;
}

sub post_save_entry {
	my ($callback, $app, $obj) = @_;

	my $blog_id = $obj->blog_id;
	my $entry_id = $obj->id;

    my $zoom_level = $app->param ('geotype_zoom_level');

    require GeoType::EntryLocation;
	my $num = 0;
	while (my $location_name = $app->param("geotype_locname_$num")) {
       	my $entry_location;
        if (my $id = $app->param ("geotype_location_id_$num")) {
            $entry_location = GeoType::EntryLocation->load ($id);
        }
        else {
            $entry_location = GeoType::EntryLocation->new;
            $entry_location->entry_id ($entry_id);
            $entry_location->blog_id ($blog_id);
        }
        
        if (!$app->param ("geotype_addr_$num") && $entry_location->id) {
            # We need to check for a removed location
            # In that case, there is a location id present, but no location
            
            $entry_location->remove or return $callback->error ("Error removing entry location: " . $entry_location->errstr);
        }
        
        # at this point, we've handled the removed location case,
        # so only continue if there actually is something there
        next unless ($app->param ("geotype_addr_$num"));

        # my $location_name = $app->param("geotype_locname_$num");
        my $location_addr = $app->param("geotype_addr_$num");
        my $geometry = $app->param("geotype_geometry_$num");

    	my $location = GeoType::Location->get_by_key ({ location => $location_addr, blog_id => $blog_id });		
    	$location->name($location_name);
    	$location->geometry($geometry);
    	$location->visible(1);
    	$location->save or return $callback->error ("Saving location failed: ", $location->errstr);
    	
        $entry_location->zoom_level ($zoom_level);
    	$entry_location->location_id($location->id);
        $entry_location->save or return $callback->error ("Saving entry_location failed: ", $entry_location->errstr);
		$num++;
    }

}

sub get_locations_for_entry {
	my $entry = shift;

    my @entry_locations = GeoType::EntryLocation->load ({ entry_id => $entry->id });
    my @locations;
    
    foreach my $entry_location (@entry_locations) {
        my $location = GeoType::Location->load ($entry_location->location_id);
        push @locations, $location if ($location);
    }
    return @locations;
}

sub get_zoom_for_entry {
    my $entry = shift;
    my @locations = GeoType::EntryLocation->load ({ entry_id => $entry->id });
    
    my $zoom;
    foreach (@locations) {
        $zoom = $_->zoom_level if ($_->zoom_level);
    }
    
    return $zoom;
}

sub geo_type_coords_tag {
    my $ctx = shift;
    my $entry = $ctx->stash('entry');
    my ($location) = get_locations_for_entry($entry);

    return $location ? $location->geometry : "";
}

sub geo_type_location_tag {
    my $ctx = shift;
    my $entry = $ctx->stash('entry');
    my ($location) = get_locations_for_entry($entry);

    return $location ? $location->location : "";
}

sub geo_type_if_location_tag  {
    return geo_type_location_tag (@_);
}

sub get_google_api_key {
    my $plugin = shift;
    my ($blog, $which) = @_;
    
    my $interface_api_key =  $plugin->_get_api_key ($blog, 'google');
    my $site_api_key      =  $plugin->get_config_value ('site_api_key', 'blog:' . $blog->id) || $interface_api_key;
    
    return $which && $which eq 'site' ? $site_api_key : $interface_api_key;
}

sub _get_api_key {
    my $plugin = shift;
    my ($blog, $key) = @_;
    
    my $system_value = $plugin->get_config_value ($key . '_api_key', 'system');
    my $blog_value   = $plugin->get_config_value ($key . '_api_key', 'blog:' . $blog->id);
    
    return $blog_value && $blog_value ne uc($key . '_api_key') ? $blog_value : $system_value ne uc($key . '_api_key') ? $system_value : undef;
}

sub list_locations {
    my ($app) = @_;
    
    $app->{breadcrumbs} = [];
    $app->add_breadcrumb ('GeoType: List Locations');
    
    return $app->listing ({
        Type    => 'geotype_location',
        Terms   => {
            blog_id => $app->blog->id
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
            quick_search    => 0,
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
    		
        },
    });
}

1;

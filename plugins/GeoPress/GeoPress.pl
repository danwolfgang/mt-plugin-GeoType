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

package MT::Plugin::GeoPress; 
use base qw(MT::Plugin);
use strict;
use warnings;

use MT;
use GeoPress::Location;
use GeoPress::EntryLocation;

use vars qw( $VERSION );
$VERSION = 1.01; 

my $plugin = MT::Plugin::GeoPress->new ({
    name        => "GeoPress",
	key         => "GeoPress",
    version     => $VERSION,
    description => "<MT_TRANS phrase=\"GeoPress allows you to specify the location for any blog post and inserting maps, coordinates, location names in the post. You can also add GeoRSS to your RSS or Atom syndication feeds, and KML to visualize blog post locations in GoogleEarth.<br\><br\>GeoPress settings are on a per-blog setting, so you'll need to set this up in each weblog you administer. Use the 'GeoPress' link in the left sidebar under 'Utilities' to configure your Map defaults and Locations.\">",
    author_name => "Andrew Turner",
    author_link => "http://highearthorbit.com/",
    plugin_link => "http://georss.org/geopress/",
	doc_link    => "http://georss.org/geopress/",

	schema_version => 1.01,
 	object_classes => [ 'GeoPress::Location', 'GeoPress::EntryLocation' ],
	
	config_link     => 'geopress.cgi',
	config_template => 'config.tmpl',
    settings        => MT::PluginSettings->new ([
        [ 'google_api_key', 	    { Default => 'GOOGLE_API_KEY',  Scope => 'system' } ],
        [ 'yahoo_api_key', 	        { Default => 'YAHOO_API_KEY',   Scope => 'system' } ],
        [ 'microsoft_map', 	        { Default => 0,                 Scope => 'system' } ],
        [ 'google_api_key', 	    { Default => 'GOOGLE_API_KEY',  Scope => 'blog' } ],
        [ 'yahoo_api_key', 	        { Default => 'YAHOO_API_KEY',   Scope => 'blog' } ],
        [ 'microsoft_map', 	        { Default => 0,                 Scope => 'blog' } ],
        [ 'georss_format', 	        { Default => 'simple',          Scope => 'blog' } ],
        [ 'georss_enable', 	        { Default => 1,                 Scope => 'blog' } ],
        [ 'map_width', 		        { Default => '200',             Scope => 'blog' } ],
        [ 'map_height', 		    { Default => '200',             Scope => 'blog' } ],
        [ 'default_map_format', 	{ Default => 'google',          Scope => 'blog' } ],
        [ 'default_map_type', 		{ Default => 'HYBRID',          Scope => 'blog' } ],
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
	},
	
	template_tags => {
			'GeoPressCoords' => \&geo_press_coords_tag,
			'GeoPressLocation' => \&geo_press_location_tag,
			'GeoPressMap' => \&geo_press_map_tag,
			'GeoPressHeader' =>\&geo_press_header_tag,
			'GeoRSS_Namespace' =>\&geo_rss_namespace_tag,
			'GeoRSS_Channel' =>\&geo_rss_channel_tag,
			'GeoRSS_Entry' =>\&geo_rss_entry_tag,
	},
	
    app_action_links => {
        'MT::App::CMS' => {   # application the action applies to
            'blog' => {
                link => 'geopress.cgi?__mode=view',
                link_text => 'Edit GeoPress Locations'
            },
        }
    }
});

MT->add_plugin($plugin);

sub instance { $plugin; }
	
sub left_nav {
    my ($eh, $app, $tmpl) = @_;
    my $slug = <<END_TMPL;
<li><a style="background-image: url(<TMPL_VAR NAME=STATIC_URI>images/nav_icons/color/plugins.gif);" <TMPL_IF NAME=NAV_MEDIAMANAGER>class="here"</TMPL_IF> id="nav-mmanager" title="<MT_TRANS phrase="GeoPress">" href="<TMPL_UNLESS NAME=GPSCRIPT_URL><TMPL_VAR NAME=SCRIPT_PATH>plugins/GeoPress/</TMPL_UNLESS>geopress.cgi?__mode=view&amp;blog_id=<TMPL_VAR NAME=BLOG_ID><TMPL_VAR NAME=CONTEXT_URI>"><MT_TRANS phrase="GeoPress"></a></li>
END_TMPL
    $$tmpl =~ s/(<li><MT_TRANS phrase=\"Utilities\">\n<ul class=\"sub\">)/$1$slug/;
}

# Creates an actual map for an entry
sub geo_press_map_tag {
	my $ctx = shift;
	my $entry = $ctx->stash('entry');
	my $blog_id = $ctx->stash('blog_id');
	
	my $location = get_location_for_entry($entry);

 	my $config = $plugin->get_config_hash('blog:' . $blog_id);	

	if ($location && $location->geometry ne "") {
		my $tmpl = $plugin->load_tmpl("map.tmpl");
		$tmpl->param(default_map_format => $config->{default_map_format});
		$tmpl->param(map_width => $config->{map_width});
		$tmpl->param(map_height => $config->{map_height});
		$tmpl->param(geometry => $location->geometry);
		$tmpl->param(location_name => $location->name);
		$tmpl->param(map_id => $entry->id);
		return $tmpl->output;
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
	my $location = get_location_for_entry($entry);
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
sub geo_press_header_tag {
    my ($ctx) = @_;
    
    my $blog;
    if ($ctx) {
        $blog = $ctx->stash ('blog');
    }
    else {
        require MT::App;
        $blog = MT::App->instance->blog;
    }
	my $tmpl = $plugin->load_tmpl("geopress_header.tmpl");

	$tmpl->param(geopress_version => $VERSION);
	# Build up the keys
	my $google_api_key = $plugin->get_google_api_key ($blog);
	if ($google_api_key && $google_api_key ne 'GOOGLE_API_KEY') { $tmpl->param(google_api_key => $google_api_key); }

	my $yahoo_api_key = $plugin->get_yahoo_api_key ($blog);
	if ($yahoo_api_key && $yahoo_api_key ne 'YAHOO_API_KEY')  {$tmpl->param(yahoo_api_key => $yahoo_api_key); }

	my $microsoft_map = $plugin->get_config_value ('microsoft_map', 'blog:' . $blog->id);
	if ($microsoft_map)  {$tmpl->param(microsoft_map => $microsoft_map); }

	$tmpl->output;
}

# Creates the Edit form when writing an entry
sub _edit_entry {
    my ($cb, $app, $tmpl) = @_;
	my $blog = $app->blog;
    my $config = $plugin->get_config_hash('system');
	my $google_api_key = $plugin->get_google_api_key ($blog);
	my $yahoo_api_key = $plugin->get_yahoo_api_key ($blog);
	my $microsoft_map = $config->{microsoft_map};
	
	my ($old, $new);
	$old = qq{<TMPL_IF NAME=DISP_PREFS_SHOW_EXCERPT>};
    # $old = quotemeta($old);
		
	if ($google_api_key ne "GOOGLE_API_KEY" || $yahoo_api_key ne "YAHOO_API_KEY" || $microsoft_map ne 0) {
		my $entry_id = $app->param('id');
		my $entrylocation = GeoPress::EntryLocation->get_by_key ({entry_id => $entry_id});
		my $location = GeoPress::Location->get_by_key ({ id => $entrylocation->location_id });
		my $location_name = $location->name;
		my $location_addr = $location->location;
		my $location_geometry = $location->geometry;

		my $header = geo_press_header_tag;
		my $tmpl = $plugin->load_tmpl("geopress_edit.tmpl") or return $cb->error ("Error loading template: ", $plugin->errstr);

		my $saved_locations = "";
		my @locations = grep { $_->visible } GeoPress::Location->load ({ blog_id => $blog->id });
		$tmpl->param ( saved_locations_loop => [ map { { location_value => $_->location, location_name => $_->name } } @locations ] );

        $tmpl->param ( new_location => 1 ) if (!$location_geometry);

		$tmpl->param(saved_locations => $saved_locations);
		$tmpl->param(location_addr => $location_addr);
		$tmpl->param(location_name => $location_name);
		$tmpl->param(location_geometry => $location_geometry);
		$new = $header.($tmpl->output);
	} else {
		$new = "<p>To Enable GeoPress, add the appropriate mapping library keys in your settings.</p>";
	}
	$$tmpl =~ s/\Q$old\E/$new\n$old\n/;
}

sub post_save_entry {
	my ($callback, $app, $obj, $original) = @_;

    return unless ($app->param ('geopress_addr'));

	my $blog_id = $obj->blog_id;
	my $entry_id = $obj->id;
	
	# no need to test if these already exist - get_by_key will create them if they don't
	my $entry_location = GeoPress::EntryLocation->get_by_key ({ entry_id => $entry_id, blog_id => $blog_id });

    my $location_name = $app->param('geopress_locname');
    my $location_addr = $app->param('geopress_addr');
    my $geometry = $app->param('geopress_geometry');

	my $location = GeoPress::Location->get_by_key ({ location => $location_addr, blog_id => $blog_id });		
	$location->name($location_name);
	$location->geometry($geometry);
	$location->visible(1);
	$location->save or return $callback->error ("Saving location failed: ", $location->errstr);
	  
	$entry_location->location_id($location->id);
	$entry_location->save or return $callback->error ("Saving entry_location failed: ", $entry_location->errstr);
}

sub get_location_for_entry {
	my $entry = shift;

	my $entry_location = GeoPress::EntryLocation->get_by_key({entry_id => $entry->id});
	my $location = GeoPress::Location->get_by_key({ id => $entry_location->location_id });		
    return $location;
}

sub geo_press_coords_tag {
    my $ctx = shift;
    my $entry = $ctx->stash('entry');
    my $location = get_location_for_entry($entry);

    return $location ? $location->geometry : "";
}

sub geo_press_location_tag {
    my $ctx = shift;
    my $entry = $ctx->stash('entry');
    my $location = get_location_for_entry($entry);

    return $location ? $location->location : "";
}

sub get_google_api_key {
    my $plugin = shift;
    my ($blog) = @_;
    
    return $plugin->_get_api_key ($blog, 'google');
}

sub get_yahoo_api_key {
    my $plugin = shift;
    my ($blog) = @_;
    
    return $plugin->_get_api_key ($blog, 'yahoo');
}


sub _get_api_key {
    my $plugin = shift;
    my ($blog, $key) = @_;
    
    my $system_value = $plugin->get_config_value ($key . '_api_key', 'system');
    my $blog_value   = $plugin->get_config_value ($key . '_api_key', 'blog:' . $blog->id);
    
    return $blog_value && $blog_value ne uc($key . '_api_key') ? $blog_value : $system_value;
}

1;
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

use MT;
use GeoPress::Location;
use GeoPress::EntryLocation;

# @MT::Plugin::GeoPress::ISA = qw(MT::Plugin);
use vars qw( $VERSION );
$VERSION = 1.01; 


	my $plugin = MT::Plugin::GeoPress->new ({
    name => "GeoPress",
		key => "GeoPress",
    version => $VERSION,
    description => "<MT_TRANS phrase=\"GeoPress allows you to specify the location for any blog post and inserting maps, coordinates, location names in the post. You can also add GeoRSS to your RSS or Atom syndication feeds, and KML to visualize blog post locations in GoogleEarth.<br\><br\>GeoPress settings are on a per-blog setting, so you'll need to set this up in each weblog you administer. Use the 'GeoPress' link in the left sidebar under 'Utilities' to configure your Map defaults and Locations.\">",
    author_name => "Andrew Turner",
    author_link => "http://highearthorbit.com/",
    plugin_link => "http://georss.org/geopress/",
		doc_link    => "http://georss.org/geopress/",
	  config_link => 'geopress.cgi',
	  config_template => 'config.tmpl',
		schema_version => 1.01,
    settings => MT::PluginSettings->new ([
        ['google_api_key', 	{Default => 'GOOGLE_API_KEY', Scope => 'system'}],
        ['yahoo_api_key', 	{Default => 'YAHOO_API_KEY', Scope => 'system'}],
        ['microsoft_map', 	{Default => 0, Scope => 'system'}],
        ['google_api_key', 	{Default => 'GOOGLE_API_KEY', Scope => 'blog'}],
        ['yahoo_api_key', 	{Default => 'YAHOO_API_KEY', Scope => 'blog'}],
        ['microsoft_map', 	{Default => 0, Scope => 'blog'}],
        ['georss_format', 	{Default => 'simple', Scope => 'blog'}],
        ['georss_enable', 	{Default => 1, Scope => 'blog'}],
        ['map_width', 			{Default => '200', Scope => 'blog'}],
        ['map_height', 			{Default => '200', Scope => 'blog'}],
        ['default_map_format', 		{Default => 'google', Scope => 'blog'}],
        ['default_map_type', 			{Default => 'HYBRID', Scope => 'blog'}],
        ['map_controls_pan', 			{Default => 1, Scope => 'blog'}],
        ['map_controls_map_type', {Default => 1, Scope => 'blog'}],
        ['map_controls_zoom', 		{Default => "small", Scope => 'blog'}],
        ['map_controls_overview', {Default => 0, Scope => 'blog'}],
        ['map_controls_scale', 		{Default => 1, Scope => 'blog'}],
        ['default_add_map', 			{Default => 'all', Scope => 'blog'}],
        ['default_zoom_level', 		{Default => 11, Scope => 'blog'}],
	    ]),
	 	object_classes => [ 'GeoPress::Location', 'GeoPress::EntryLocation' ],
		callbacks    => {
			'MT::App::CMS::AppTemplateSource.edit_entry' => \&_edit_entry,
            'MT::App::CMS::AppTemplateSource.blog-left-nav' => \&left_nav,
            'CMSPostSave.entry' => \&save_location,
		},
		template_tags => {
			'GeoPressCoords' => \&GeoPress::Location::entry_coords,
			'GeoPressLocation' => \&GeoPress::Location::entry_location,
			'GeoPressMap' => \&entry_map,
			'GeoPressHeader' =>\&_geopress_headers,
			'GeoRSS_Namespace' =>\&_geopress_georss_ns,
			'GeoRSS_Channel' =>\&_geopress_georss_channel,
			'GeoRSS_Entry' =>\&_geopress_georss_entry,
		},
    app_action_links => {
        'MT::App::CMS' => {   # application the action applies to
            'blog' => {
                link => 'geopress.cgi',
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
sub entry_map {
	my $ctx = shift;
	my $entry = $ctx->stash('entry');
	my $blog_id = $ctx->stash('blog_id');
	
	my $location = GeoPress::Location::get_location_for_entry($entry);

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
		
sub _geopress_georss_ns {
    my $ctx = shift;
	use MT::App;

	my $blog_id = $ctx->stash('blog_id');
  my $config = $plugin->get_config_hash('blog:' . $blog_id);	

	my $georss_enable = $config->{georss_enable};		
	if( ! $georss_enable ) {
		return "";
	}
	
	my $georss_format = $config->{georss_format};	
	if($georss_format eq "simple") {
		return qq{ xmlns:georss="http://www.georss.org/georss"};
	}
	elsif ($georss_format eq "gml") {
	 	return qq{ xmlns:georss="http://www.georss.org/georss" xmlns:gml="http://www.opengis.net/gml"};
	}
	elsif ($georss_format eq "w3c") {
	 	return qq{ xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"};
	}
}	
sub _geopress_georss_channel {
    my $ctx = shift;
	use MT::App;
	my $blog_id = $ctx->stash('blog_id');
  my $config = $plugin->get_config_hash('blog:' . $blog_id);	
	my $georss_format = $config->{georss_format};	

	my $georss_enable = $config->{georss_enable};		
	if( ! $georss_enable ) {
		return "";
	}
	
	return "";
}
sub _geopress_georss_entry {
    my $ctx = shift;
	use MT::App;


	my $entry = $ctx->stash('entry');
	my $blog_id = $ctx->stash('blog_id');
	my $location = GeoPress::Location::get_location_for_entry($entry);
  my $config = $plugin->get_config_hash('blog:' . $blog_id);	

	my $georss_enable = $config->{georss_enable};		
	if( ! $georss_enable ) {
		return "";
	}
	
	my $georss_format = $config->{georss_format};	
	my $georss_entry;
	my $geometry = $location->geometry;
	if($georss_format eq "simple") {
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
	 	$georss_entry = qq{<geo:lat>@coords[0]</geo:lat><geo:long>@coords[1]</geo:long>};
	}
	return $georss_entry;
}

# Tag to add the necessary mapping headers 
#TODO - figure out how to have this get included automatically
sub _geopress_headers {
  my $ctx = shift;
	my $blog_id;
	my $config;
	if(defined $ctx) {
		$blog_id = $ctx->stash('blog_id');
  	$config = $plugin->get_config_hash('blog:' . $blog_id);
	}
	else {
		# We're in the admin interface, get things differently
		use MT::App;
		my $app = MT::App->instance;
		$blog_id = $app->blog->id;
  	$config = $plugin->get_config_hash('system');
	}

	my $tmpl = $plugin->load_tmpl("geopress_header.tmpl");

	use MT::App;
	my $app = MT::App->instance;

	$tmpl->param(geopress_version => $VERSION);
	# Build up the keys
	my $google_api_key = $config->{google_api_key};	
	if($google_api_key) { $tmpl->param(google_api_key => $google_api_key); }

	my $yahoo_api_key = $config->{yahoo_api_key};	
	if($yahoo_api_key)  {$tmpl->param(yahoo_api_key => $yahoo_api_key); }

	my $microsoft_map = $config->{microsoft_map};	
	if($microsoft_map)  {$tmpl->param(microsoft_map => $microsoft_map); }

	$tmpl->output;
}

# Creates the Edit form when writing an entry
sub _edit_entry {
   my ($cb, $app, $tmpl) = @_;
	my $blog = $app->blog;
  my $config = $plugin->get_config_hash('system');
	my $google_api_key = $config->{google_api_key};
	my $yahoo_api_key = $config->{yahoo_api_key};
	my $microsoft_map = $config->{microsoft_map};
	
	my ($old, $new);
	$old = qq{<TMPL_IF NAME=DISP_PREFS_SHOW_EXCERPT>};
	$old = quotemeta($old);
		
	if($google_api_key ne "GOOGLE_API_KEY" || $yahoo_api_key ne "YAHOO_API_KEY" || $microsoft_map ne 0) {
		my $entry_id = $app->{query}->param('id');
		my $entrylocation = GeoPress::EntryLocation->get_by_key({entry_id => $entry_id});
		my $location = GeoPress::Location->get_by_key({ id => $entrylocation->location_id });
		my $location_name = $location->name;
		my $location_addr = $location->location;
		my $location_geometry = $location->geometry;

		my $header = _geopress_headers;
		my $tmpl = $plugin->load_tmpl("geopress_edit.tmpl");

		my $saved_locations = "";
		my @locations = GeoPress::Location->load({ blog_id => $blog->id });
		foreach $location(@locations) {
			if( $location->visible) {
				$saved_locations = $saved_locations . "<option value=\"" . $location->location . "\">" . $location->name . "</option>";
				# $saved_locations = $saved_locations . qq{<option value="test">test</option>};
			}
		}

		if( !$location_geometry) {
			$tmpl->param(new_location => 1);
			# $location_geometry = "20, -20";
		}
		else {
			
		}
		$tmpl->param(saved_locations => $saved_locations);
		$tmpl->param(location_addr => $location_addr);
		$tmpl->param(location_name => $location_name);
		$tmpl->param(location_geometry => $location_geometry);
		$new = $header.($tmpl->output);
	} else {
		$new = "To Enable GeoPress, add the appropriate mapping library keys in your settings.";
	}
	$$tmpl =~ s/($old)/$new\n$1\n/;
}

sub save_location {
	my ($callback, $app, $obj, $original) = @_;

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


1;
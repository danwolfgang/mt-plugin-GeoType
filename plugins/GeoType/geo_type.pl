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
#   blog posts, adding maps, outputing GeoRSS and KML feeds
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
use MT::ConfigMgr;
use GeoType::Location;
use GeoType::EntryLocation;
use GeoType::ExtendedLocation;

use vars qw( $VERSION );
$VERSION = '1.6.8.3'; 

my $plugin = MT::Plugin::GeoType->new ({
    id          => 'GeoType',
	name        => "GeoType",
	key         => "GeoType",
	version     => $VERSION,
	description => "<MT_TRANS phrase=\"GeoType allows you to specify the location for any blog post and inserting maps, coordinates, location names in the post. You can also add GeoRSS to your RSS or Atom syndication feeds, and KML to visualize blog post locations in GoogleEarth.<br\><br\>GeoType settings are on a per-blog setting, so you'll need to set this up in each weblog you administer.\">",
	author_name => "Apperceptive, LLC",
	author_link => "http://apperceptive.com/",

	schema_version => 1.3,
        upgrade_functions => {
                'geotype_add_location_basename' => {
                        version_limit => 1.3,
						code => \&save_all_locations,
                }
	},
	object_classes => [ 'GeoType::Location', 'GeoType::EntryLocation', 'GeoType::ExtendedLocation' ],
	
	system_config_template  => 'config.tmpl',
	blog_config_template    => 'blog_config.tmpl',
	settings        => MT::PluginSettings->new ([
		[ 'google_api_key',         { Default => 'GOOGLE_API_KEY',  Scope => 'system' } ],
		[ 'google_api_key',         { Default => 'GOOGLE_API_KEY',  Scope => 'blog' } ],
		[ 'site_api_key',           { Default => '',                Scope => 'blog' } ],
		[ 'georss_format',             { Default => 'simple',          Scope => 'blog' } ],
		[ 'georss_enable',             { Default => 1,                 Scope => 'blog' } ],
		[ 'map_width',                 { Default => '200',             Scope => 'blog' } ],
		[ 'map_height',             { Default => '200',             Scope => 'blog' } ],
		[ 'default_map_type',         { Default => 'G_HYBRID_MAP',    Scope => 'blog' } ],
		[ 'map_controls_pan',         { Default => 1,                 Scope => 'blog' } ],
		[ 'map_controls_map_type',  { Default => 1,                 Scope => 'blog' } ],
		[ 'map_controls_zoom',         { Default => "small",           Scope => 'blog' } ],
		[ 'map_controls_overview',  { Default => 0,                 Scope => 'blog' } ],
		[ 'map_controls_scale',     { Default => 1,                 Scope => 'blog' } ],
		[ 'default_add_map',         { Default => 'all',             Scope => 'blog' } ],
		[ 'default_zoom_level',     { Default => 11,                Scope => 'blog' } ],
		[ 'use_extended_attributes', { Default => 0,                Scope => 'blog' } ],
		[ 'hide_saved_locations', { Default => 0,                Scope => 'blog' } ],
		]),
	
	callbacks    => {
			'MT::App::CMS::AppTemplateSource.edit_entry' => \&_edit_entry,
			'MT::App::CMS::AppTemplateSource.blog-left-nav' => \&left_nav,
			'CMSPostSave.entry' => \&post_save_entry,
			
			'CMSPostDelete.geotype_location'   => \&post_delete_location,
	},
	
	container_tags => {
			'GeoTypeLocations' => \&geo_type_location_container,
	},
	template_tags => {
			'GeoTypeLocationName' => \&geo_type_name_tag,
			'GeoTypeLocationId' => \&geo_type_id_tag,
			'GeoTypeLocationGUID' => \&geo_type_GUID_tag,
			'GeoTypeLocationLatitude' => \&geo_type_latitude_tag,
			'GeoTypeLocationLongitude' => \&geo_type_longitude_tag,
			'GeoTypeLocationCrossStreet' => \&geo_type_cross_street_tag,
			'GeoTypeLocationDescription' => \&geo_type_description_tag,
			'GeoTypeLocationHours' => \&geo_type_hours_tag,
			'GeoTypeLocationPhone' => \&geo_type_phone_tag,
			'GeoTypeLocationPlaceId' => \&geo_type_place_id_tag,
			'GeoTypeLocationRating' => \&geo_type_rating_tag,
			'GeoTypeLocationThumbnail' => \&geo_type_thumbnail_tag,
			'GeoTypeLocationURL' => \&geo_type_URL_tag,
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
			'GeoTypeIfLocationExtended'  => \&geo_type_if_location_extended,
	},
	
	app_methods => {
	   'MT::App::CMS'  => {
		   'geotype_list_location'  => \&list_location,
		   'geotype_edit_location'  => \&edit_extended_location,
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

sub save_all_locations {
	my $iter = GeoType::Location->load_iter({});
	while ( my $loc = $iter->() ) {
		$loc->save;
	}
}

sub load_config {
	my $plugin = shift;
	$plugin->SUPER::load_config (@_);
	my ($param, $scope) = @_;
	
	if ($scope =~ /^blog:\d+$/) {
		$param->{geotype_header} = geo_type_header_tag();
	}
}


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

sub _check_MTE {
	return 0 unless ( defined(&MT::product_name) );
	return 0 unless ( &MT::product_name eq 'Movable Type Enterprise' );
	return 1;	
}
	
sub left_nav {
	my ($eh, $app, $tmpl) = @_;
        unless ( &_check_MTE() ) {
		return $tmpl;
	}
	my $slug = <<END_TMPL;
<li><a style="background-image: url(<TMPL_VAR NAME=STATIC_URI>images/nav_icons/color/plugins.gif);" <TMPL_IF NAME=NAV_MEDIAMANAGER>class="here"</TMPL_IF> id="nav-mmanager" title="<MT_TRANS phrase="GeoType">" href="<TMPL_VAR NAME=MT_URL>?__mode=geotype_list_location&amp;blog_id=<TMPL_VAR NAME=BLOG_ID>"><MT_TRANS phrase="GeoType"></a></li>
END_TMPL
	$$tmpl =~ s/(<li><MT_TRANS phrase=\"Utilities\">\n<ul class=\"sub\">)/$1$slug/;
}

sub init_cms {
	my $plugin = shift;
	my $app = shift;
        if ( &_check_MTE() ) {
                $app->register_type ('geotype_location', 'GeoType::Location');
        }
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
					location_real_id => $location->id,
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
		$tmpl->param ( use_extended_attributes => $plugin->get_config_value ('use_extended_attributes', 'blog:'. $app->blog->id) );
		$tmpl->param ( script_dir => $app->base .  $app->uri );
		$tmpl->param ( entry_id => $entry_id );
		$tmpl->param ( blog_id => $app->blog->id );
		$tmpl->param ( location_num => $#location_loop, location_loop => \@location_loop );

		my @locations = grep { $_->visible } GeoType::Location->load ({ blog_id => $blog->id }, { sort => 'name' } );
		$tmpl->param ( hide_saved_locations => $plugin->get_config_value ('hide_saved_locations', 'blog:'. $app->blog->id) );
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

sub get_locations_for_archive {
	my $ctx = shift;
	my @entry_locations;
	my $entries = $ctx->stash('entries');
	my @entries = @$entries;
	my @locations;
	foreach my $entry ( @entries ) {
		next unless ( $entry->id );
		my @entry_locations = GeoType::EntryLocation->load ({ entry_id => $entry->id });
		foreach my $entry_location (@entry_locations) {
			my $location = GeoType::Location->load ($entry_location->location_id);
			push @locations, $location if ($location);
		}
	}
	return @locations;
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
        my $location = $ctx->stash('geotype_location');
        if ( $location ) {
                return $location->geometry;
        }
	my $entry = $ctx->stash('entry');
	( $location ) = get_locations_for_entry($entry);

	return $location ? $location->geometry : "";
}

sub geo_type_location_tag {
	my $ctx = shift;
	my $location = $ctx->stash('geotype_location');
	if ( $location ) {
        	return $location->location;
	}

	my $entry = $ctx->stash('entry');
	( $location ) = get_locations_for_entry($entry);

	return $location ? $location->location : "";
}

sub geo_type_if_location_tag  {
	return geo_type_location_tag (@_);
}

sub location_entry_feed {
	my ($app) = @_;
}

1;


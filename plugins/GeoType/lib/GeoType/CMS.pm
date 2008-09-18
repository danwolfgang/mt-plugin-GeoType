
package GeoType::CMS;

use strict;
use warnings;

use MT;
use GeoType::Util;

# sub list_location {
#   my ($app) = @_;
#   
#   my $plugin = MT->component ('geotype');
#   
#   $app->{breadcrumbs} = [];
#   $app->add_breadcrumb ('GeoType: List Locations');
#   my $offset = $app->param ('offset');
#   $offset ||= 0;
#   my ( $start_offset, $end_offset, $total_rows );
#   $total_rows = GeoType::Location->count({ blog_id => $app->blog->id });
#   if ( $offset > $total_rows ) {
#       $offset = $total_rows - 20;
#   }
#   if ( $offset < 0 ) {
#       $offset = 0;
#   }
#   $start_offset = $total_rows ? $offset + 1 : 0;
#   $end_offset = ( $total_rows > $start_offset + 19 ) ? $start_offset + 19 : $total_rows;
#   return $app->listing ({
#       Type    => 'geotype_location',
#       Offset  => $offset,
#       Terms   => {
#           blog_id => $app->blog->id
#       },
#       Args    => {
#           sort => 'name',
#       },
#       Code    => sub {
#           my ($obj, $row) = @_;
#           $row->{location_visible} = $obj->visible;
#           $row->{location_id} = $obj->id;
#           $row->{location_name} = $obj->name;
#           $row->{location_address} = $obj->location;
#           $row->{location_geometry} = $obj->geometry;
#           
#           require GeoType::EntryLocation;
#           $row->{entries_count} = GeoType::EntryLocation->count ({ location_id => $obj->id });
#           
#       },
#       Template    => $plugin->load_tmpl ('list_geotype_location.tmpl'),
#       Params  => {
#           offset      => $offset,
#           start_offset    => $start_offset,
#           prev_page   => ( $start_offset > 20 ) ? $start_offset - 21 : 0,
#           last_page   => $total_rows - 20,
#           end_offset  => $end_offset,
#           total_rows  => $total_rows,
#           forward_arrow   => ( $end_offset < $total_rows) ? 1 : 0,
#           back_arrow  => ( $start_offset > 1 ) ? 1 : 0,
#           quick_search    => 0,
#           extensions      => $plugin->get_config_value ('use_extended_attributes', 'blog:'. $app->blog->id),
#           google_api_key  => $plugin->get_google_api_key ($app->blog),
#           map_height      => $plugin->get_config_value ('map_height', 'blog:'. $app->blog->id),
#           map_width       => $plugin->get_config_value ('map_width', 'blog:' . $app->blog->id),
#           default_zoom_level => $plugin->get_config_value ('default_zoom_level', 'blog:' . $app->blog->id),
#           default_map_type => $plugin->get_config_value ('default_map_type', 'blog:' . $app->blog->id),
#           map_width => $plugin->get_config_value ('map_width', 'blog:' . $app->blog->id),
#           map_height => $plugin->get_config_value ('map_height', 'blog:' . $app->blog->id),
# 
#           map_controls_overview => $plugin->get_config_value ('map_controls_overview', 'blog:' . $app->blog->id),
#           map_controls_scale => $plugin->get_config_value ('map_controls_scale', 'blog:' . $app->blog->id),
#           map_controls_map_type => $plugin->get_config_value ('map_controls_map_type', 'blog:' . $app->blog->id),
#           "map_controls_zoom_" .$plugin->get_config_value ('map_controls_zoom', 'blog:' . $app->blog->id) => 1,
#           
#           geotype_header  => geo_type_header_tag,
#           
#       },
#   });
# }
# 
# sub edit_extended_location {
#   my ($app) = @_;
#         my $param = { };
#   my $plugin = MT->component ('geotype');
# 
#   my $blog_id = $app->param('blog_id');
#   my $location_id = $app->param('location_id');
#   $param->{blog_id} = $blog_id;
#   $param->{location_id} = $location_id;
# 
#   ( $location_id ) or die "Location ID not provided\n";
#   # We need a location, but we may not have extended attributes
#   my $location = GeoType::Location->load( $location_id );
#   ( $location ) or die "Cannot load location ID $location_id\n";
#   my ( $extended ) = GeoType::ExtendedLocation->load({ location_id => $location_id });
#   if ( $app->param('dosave') ) {
#       $app->param('name') && $location->name($app->param('name'));
#       $extended = GeoType::ExtendedLocation->new unless ( $extended );
#       $extended->location_id($location_id);
#       $extended->cross_street($app->param('cross_street'));
#       $extended->description($app->param('description'));
#       $extended->hours($app->param('hours'));
#       $extended->phone_number($app->param('phone_number'));
#       $extended->place_id($app->param('place_id'));
#       my $rating = $app->param('rating');
#       $rating = "" unless ( $rating eq $rating + 0 );
#       $extended->rating($rating);
#       $extended->thumbnail($app->param('thumbnail'));
#       $extended->url($app->param('url'));
#       $location->save;
#       $extended->save;
#   }
# 
#   $param->{loc_name} = $location->name;
#   if ( $extended ) {
#       $param->{loc_description} = $extended->description;
#       $param->{loc_cross_street} = $extended->cross_street;
#       $param->{loc_hours} = $extended->hours;
#       $param->{loc_phone_number} = $extended->phone_number;
#       $param->{loc_place_id} = $extended->place_id;
#       $param->{loc_rating} = $extended->rating;
#       $param->{loc_thumbnail} = $extended->thumbnail;
#       $param->{loc_url} = $extended->url;
#   }
#   $app->{breadcrumbs} = [];
#   $app->add_breadcrumb('Edit Location');
#   $param->{script_url} = MT::ConfigMgr->instance->CGIPath . MT::ConfigMgr->instance->AdminScript;
#   if ( $app->param('return_to_entry') ) {
#       $param->{return_entry} = $app->param('return_to_entry');
#   }
#   my $tmpl = $plugin->load_tmpl("geotype_edit_extended.tmpl");
#         $app->build_page($tmpl, $param);
#   $app->build_page($tmpl);
# }

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

sub source_edit_entry {
    my ($cb, $app, $tmpl) = @_;
    my $old = q{<div id="feedback-field"};
    my $new = q{<div id="location-field">
    <mt:setvarblock name="location_header_action">
        <a href="javascript:void(0)" class="add-new-category-link button" onclick="openDialog(this.form, 'list_assets', 'filter=class&filter_val=location&edit_field=location_list&blog_id=<$mt:var name="blog_id"$>&dialog_view=1')" title="<__trans phrase="Add location">"><__trans phrase="add"/></a>
    </mt:setvarblock>
    
    <mtapp:widget
        id="entry-location-widget"
        label="Locations"
        header_action="$location_header_action">
        <mt:var name="location_setting">
    </mtapp:widget>
</div>};

    $$tmpl =~ s/\Q$old\E/$new$old/;
}


sub param_edit_entry {
    my ($cb, $app, $param, $tmpl) = @_;
    my $header = $tmpl->getElementById('header_include');
    my $html_head = $tmpl->createElement('setvarblock', { name => 'html_head', append => 1 });
    my $innerHTML = q{
        <link rel='stylesheet' href="<mt:var name="static_uri">plugins/GeoType/geotype.css" />
        <script type="text/javascript">
        /* <![CDATA[ */
        var locations = <mt:if name="location_list"><mt:var name="location_list" to_json="1"><mt:else>[]</mt:else></mt:if>;
        function buildLocationList () {
            var elem = getByID ('location-list');
            elem.innerHTML = '';
            var html = '';
            for (var i = 0; i < locations.length; i++) {
                html = html + "<li class='pkg' onmouseover='DOM.addClassName(this, \"focus\")' onmouseout='DOM.removeClassName(this, \"focus\")' mt:id='" + locations[i].id + "'><strong>" + locations[i].name + '</strong><a href="javascript:void(0);" onclick="removeLocation (' + locations[i].id + ')" mt:command="remove" class="delete" title="Remove">&nbsp;<span>Remove</span></a></li>';
            }        
            elem.innerHTML = html;
            var value_elem = getByID ('location_list');
            location_list.value = locations.map (function (x) { return x.id }).join(",");
        }

        function insertLocation (id, name) {
            var new_location = new Object();
            new_location.name = name;
            new_location.id = id;
            locations[locations.length] = new_location;

            buildLocationList();
        }
        
        function removeLocation (id) {
            var new_locations = new Array();
            for (var i = 0; i < locations.length; i++) {
                if (locations[i].id != id) {
                    new_locations[new_locations.length] = locations[i];
                }
            }
            
            locations = new_locations;
            buildLocationList();
        }

        TC.attachLoadEvent (buildLocationList);
        /* ]]> */

        </script>        
};
    $html_head->innerHTML($innerHTML);
    $tmpl->insertBefore($html_head, $header);
    
    $param->{location_setting} = q{
<ul class='category-list pkg' id='location-list'>
</ul>
<input type="hidden" name="location_list" id="location_list" />
};
    
    # my $category_widget = $tmpl->getElementById ('entry-category-widget');
    # 
    # my $location_widget = $tmpl->createElement ('app:widget', { id => 'entry-location-widget', label => 'Locations' });
    # $location_widget->innerHTML ('<p>Location bits here.</p>');
    # 
    # $tmpl->insertAfter ($category_widget, $location_widget);
    
    if ($param->{id}) {
        require MT::ObjectAsset;
        my @non_embedded_assets = MT::ObjectAsset->load ({
            object_id => $param->{id},
            object_ds => 'entry',
            embedded  => 0,
        });
        my @location_list = ();
        require MT::Asset;
        for my $oa (@non_embedded_assets) {
            my $a = MT::Asset->load ($oa->asset_id);
            next unless ($a->isa ('GeoType::LocationAsset'));
            push @location_list, { id => $a->id, name => $a->name };
        }
        
        $param->{location_list} = \@location_list;
    }
}

sub param_asset_insert {
    my ($cb, $app, $param, $tmpl) = @_;
    my $plugin = $cb->plugin;

    # proceed as normal unless we detect the simple association type
    return 1 unless $app->param('edit_field') eq 'location_list';

    my $block = $tmpl->getElementById('insert_script');
    return 1 unless $block;
    my $preview_html = '';
    my $ctx = $tmpl->context;
    if (my $asset = $ctx->stash('asset')) {
        my $asset_id = $asset->id;
        my $asset_name = $asset->name;
        require MT::Util;
        $asset_name = MT::Util::encode_js ($asset_name);
        $block->innerHTML(qq{top.insertLocation($asset_id, '$asset_name');});
    }
}

sub post_save_entry {
    my ($cb, $app, $entry) = @_;
    
    my $location_list = $app->param ('location_list');
    my @ids = split(/\s*,\s*/, $location_list);
    
    require MT::ObjectAsset;

    require MT::ObjectAsset;
    my @assets = MT::ObjectAsset->load({
        object_id => $entry->id,
        blog_id => $entry->blog_id,
        object_ds => $entry->datasource,
        embedded => 0,
    });
    my %assets = map { $_->asset_id => $_->id } @assets;

    require GeoType::LocationAsset;
    for my $id (@ids) {
        my $la = GeoType::LocationAsset->load ($id) or next;
        
        my $oa = MT::ObjectAsset->set_by_key ({
            blog_id => $entry->blog_id,
            object_id => $entry->id,
            object_ds => $entry->datasource,
            asset_id => $id,
            embedded => 0
        }) or die MT::ObjectAsset->errstr;
        $assets{$id} = 0;
    }
    
    if (my @old_maps = grep { $assets{$_->asset_id} } @assets) {
        my @old_ids = map { $_->id } @old_maps;
        MT::ObjectAsset->remove( { id => \@old_ids })
            if @old_ids;
    }
    1;
}


1;

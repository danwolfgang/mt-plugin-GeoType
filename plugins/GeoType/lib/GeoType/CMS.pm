
package GeoType::CMS;

use strict;
use warnings;

use MT;
use GeoType::Util;

sub create_location {
    my $app = shift;
    
    my $entry_insert = $app->param ('entry_insert');
    my $edit_field   = $app->param ('edit_field');
    $app->load_tmpl ('dialog/create_location.tmpl', { entry_insert => $entry_insert, edit_field => $edit_field });
}

sub verify_location {
    my $app = shift;
    
    my $address = $app->param ('location_address');
    my @coords  = GeoType::Util::geocode ($app->blog, $address);
    
    my $entry_insert = $app->param ('entry_insert');
    my $edit_field   = $app->param ('edit_field');
    
    require GeoType::LocationAsset;
    my $la = GeoType::LocationAsset->new;
    $la->blog_id ($app->blog->id);
    $la->lattitude ($coords[1]);
    $la->longitude ($coords[0]);
    
    my $url = $la->thumbnail_url (Width => 600, Height => int(600 / 1.61));
    
    $app->load_tmpl ('dialog/verify_location.tmpl', { 
        edit_field  => $edit_field,
        entry_insert    => $entry_insert,
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
    
    if ($app->param ('entry_insert')) {
        require MT::CMS::Asset;
        $app->param ('id', $la->id);
        return MT::CMS::Asset::insert ($app)
    }
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
    my $blog_id = $app->blog->id;
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
            if (locations.length) {
                DOM.removeClassName ('location-list-preview', 'hidden');
            }
            else {
                DOM.addClassName ('location-list-preview', 'hidden');
            }
        }

        function insertLocation (id, name) {
            // Skip out if the id already exists in the list
            for (var i = 0; i < locations.length; i++) {
                if (locations[i].id == id) {
                    return;
                }
            }
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
        
        function openLocationPreview (f) {
            var location_list = getByID ('location_list').value;
            return openDialog (f, 'preview_locations', 'blog_id=<$mt:var name="blog_id">&location_list=' + location_list);
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
<a href="javascript:void(0)" id="location-list-preview" class="pkg center button" style="text-align: center" onclick="openLocationPreview(this.form)" title="<__trans phrase="Preview Locations">"><__trans phrase="preview"/></a>
<input type="hidden" name="location_list" id="location_list" />
};
    
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

sub preview_locations {
    my $app = shift;
    my $blog = $app->blog;
    
    my $location_list = $app->param ('location_list');
    my @ids = split (/\s*,\s*/, $location_list);
    my @locations;
    require MT::Asset;
    for my $id (@ids) {
        next unless $id;
        my $asset = MT::Asset->load ($id) or next;
        push @locations, $asset if ($asset->isa ('GeoType::LocationAsset'));
    }
    
    @locations = map { { id => $_->id, name => $_->name, geometry => $_->geometry, lat => $_->lattitude, lng => $_->longitude } } @locations;
    
    my $plugin = MT->component ('geotype');
    my $map_type = $plugin->get_config_value ('interactive_map_type', 'blog:' . $blog->id);
    my $interactive_map_scale = $plugin->get_config_value ('interactive_map_scale', 'blog:' . $blog->id);
    my $config = $plugin->get_config_hash ('blog:' . $blog->id);
    $map_type = $map_type eq 'roadmap' ? 'G_NORMAL_MAP' : $map_type eq 'satellite' ? 'G_SATELLITE_MAP' : $map_type eq 'hybrid' ? 'G_HYBRID_MAP' : $map_type eq 'terrain' ? 'G_PHYSICAL_MAP' : 'G_NORMAL_MAP';
    my $key = GeoType::Util::get_google_api_key ($blog);
    return $app->load_tmpl ('dialog/preview_locations.tmpl', {
        map_type    => $map_type,
        google_api_key  => $key,
        location_list   => \@locations,
        %$config,
    });
}

sub source_asset_list {
    my ($cb, $app, $tmpl) = @_;

    return 1 unless ($app->param ('edit_field') eq 'location_list');
    
    my $new = q{
        <img src="<mt:var name="static_uri">images/status_icons/create.gif" alt="<__trans phrase="Add New Location">" width="9" height="9" />
        <mt:unless name="asset_select"><mt:setvar name="entry_insert" value="1"></mt:unless>
        <a href="<mt:var name="script_url">?__mode=create_location&amp;blog_id=<mt:var name="blog_id">&amp;dialog_view=1&amp;entry_insert=1&amp;edit_field=<mt:var name="edit_field" escape="url">&amp;upload_mode=<mt:var name="upload_mode" escape="url">&amp;<mt:if name="require_type">require_type=<mt:var name="require_type">&amp;</mt:if>return_args=<mt:var name="return_args" escape="url"><mt:if name="user_id">&amp;user_id=<mt:var name="user_id" escape="url"></mt:if>" ><__trans phrase="Add New Location"></a>
    };
    
    $$tmpl =~ s{\Q<mt:setvarblock name="upload_new_file_link">\E.*\Q</mt:setvarblock>\E}{<mt:setvarblock name="upload_new_file_link">$new</mt:setvarblock>}ms;
}


1;

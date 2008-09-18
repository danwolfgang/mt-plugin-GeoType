
package GeoType::CMS;

use strict;
use warnings;

use MT;
use GeoType::Util;

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

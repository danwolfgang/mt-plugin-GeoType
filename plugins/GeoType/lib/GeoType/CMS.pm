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

package GeoType::CMS;

use strict;
use warnings;

use MT;
use GeoType::Util;

sub create_location {
    my $app = shift;

    my $entry_insert = $app->param('entry_insert');
    my $edit_field   = $app->param('edit_field');
    $app->load_tmpl(
        'dialog/create_location.tmpl', 
        { 
            entry_insert   => $entry_insert, 
            edit_field     => $edit_field,
            google_api_key => GeoType::Util::get_google_api_key($app->blog)
        }
    );
}

sub verify_location {
    my $app = shift;

    my $address = $app->param('location_address');
    my @coords = GeoType::Util::geocode( $app->blog, $address );

    my $entry_insert = $app->param('entry_insert');
    my $edit_field   = $app->param('edit_field');

    require GeoType::LocationAsset;
    my $la = GeoType::LocationAsset->new;
    $la->blog_id( $app->blog->id );
    $la->latitude( $coords[1] );
    $la->longitude( $coords[0] );

    #my $url = $la->thumbnail_url( Width => 600, Height => int( 600 / 1.61 ) );

    $app->load_tmpl(
        'dialog/verify_location.tmpl',
        {
            edit_field         => $edit_field,
            entry_insert       => $entry_insert,
            location_address   => $address,
            #gecoded_url        => $url,
            location_latitude  => $coords[1],
            location_longitude => $coords[0],
            google_api_key     => GeoType::Util::get_google_api_key($app->blog)
        }
    );
}

sub insert_location {
    my $app       = shift;
    my $address   = $app->param('location_address');
    my $name      = $app->param('location_name');
    my $latitude  = $app->param('location_latitude');
    my $longitude = $app->param('location_longitude');

    require GeoType::LocationAsset;
    my $la = GeoType::LocationAsset->new;
    $la->blog_id( $app->blog->id );
    $la->name($name);
    $la->location($address);
    $la->latitude($latitude);
    $la->longitude($longitude);

    $la->save or die $la->errstr;

    if ( $app->param('entry_insert') ) {
        require MT::CMS::Asset;
        $app->param( 'id', $la->id );
        return MT::CMS::Asset::insert($app);
    }
    return $app->redirect(
        $app->uri(
            'mode' => 'list_assets',
            args   => { 'blog_id' => $app->param('blog_id') }
        )
    );
}

sub source_asset_options {
    my ( $cb, $app, $tmpl ) = @_;

    my $old = q{<__trans phrase="File Options">};
    my $new =
        q{<mt:unless name="asset_is_location"><__trans phrase="File Options"><mt:else>Location Options</mt:else></mt:unless>};

    $$tmpl =~ s/\Q$old\E/$new/;
}

sub param_asset_options {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $asset_id = $param->{asset_id};

    require MT::Asset;
    my $asset = MT::Asset->load($asset_id);
    $param->{asset_is_location} = $asset->isa('GeoType::LocationAsset');
}

sub source_edit_entry {
    my ( $cb, $app, $tmpl ) = @_;
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
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $blog_id   = $app->blog->id;
    my $header    = $tmpl->getElementById('header_include');
    my $html_head = $tmpl->createElement( 'setvarblock', { name => 'html_head', append => 1 } );
    my $innerHTML = q{
        <link rel='stylesheet' href="<mt:var name="static_uri">plugins/GeoType/geotype.css" />
        <script type="text/javascript">
        /* <![CDATA[ */
        var locations = <mt:if name="location_list"><mt:var name="location_list" to_json="1"><mt:else>[]</mt:else></mt:if>;
        function locationToStr (loc) {
            var str = loc.id + "||";
            var o = [];
            for (var opt in loc.options) {
                o.push (opt + '=' + loc.options[opt]);
            }
            return str + o.join (escape('&&'));
        }

        function buildLocationList () {
            var elem = getByID ('location-list');
            elem.innerHTML = '';
            var html = '';
            for (var i = 0; i < locations.length; i++) {
                html = html + "<li class='pkg' onmouseover='DOM.addClassName(this, \"focus\")' onmouseout='DOM.removeClassName(this, \"focus\")' mt:id='" + locations[i].id + "'><strong><a href='javascript:void(0)' onclick='openLocationOptionsDialog(this.form, " + locations[i].id + ")'>" + locations[i].name + '</a></strong><a href="javascript:void(0);" onclick="removeLocation (' + locations[i].id + ')" mt:command="remove" class="delete" title="Remove">&nbsp;<span>Remove</span></a></li>';
            }
            elem.innerHTML = html;
            var value_elem = getByID ('location_list');

            value_elem.value = locations.toJSON();
            /*value_elem.value = locations.map (locationToStr).join ('==');
            # alert ("Value set to " + value_elem.value);
            # for (var i = 0; i < locations.length; i++) {
            #
            # }*/
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
            new_location.options = {};
            locations[locations.length] = new_location;

            buildLocationList();
        }

        function updateLocationOptions (id, options) {
            for (var i = 0; i < locations.length; i++) {
                if (locations[i].id == id) {
                    locations[i].options = options;
                }
            }
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
            return openDialog (f, 'preview_locations', 'blog_id=<$mt:var name="blog_id"$>&location_list=' + escape (location_list));
        }

        function openLocationOptionsDialog (f, id) {
            var location;
            for (var i = 0; i < locations.length; i++) {
                if (locations[i].id == id) {
                    location = locations[i];
                }
            }
            return openDialog (f, 'location_options', 'blog_id=<$mt:var name="blog_id"$>&location_id=' + location.id + "&location_options=" + escape(Object.toJSON(location.options)));
        }

        TC.attachLoadEvent (buildLocationList);
        /* ]]> */

        </script>
};
    $html_head->innerHTML($innerHTML);
    $tmpl->insertBefore( $html_head, $header );

    $param->{location_setting} = q{
<ul class='category-list pkg' id='location-list'>
</ul>
<a href="javascript:void(0)" id="location-list-preview" class="pkg center button" style="text-align: center" onclick="openLocationPreview(this.form)" title="<__trans phrase="Preview Locations">"><__trans phrase="preview"/></a>
<input type="hidden" name="location_list" id="location_list" />
};

    if ( $param->{id} ) {
        require MT::ObjectAsset;
        my @non_embedded_assets = MT::ObjectAsset->load(
            {
                object_id => $param->{id},
                object_ds => 'entry',
                embedded  => 0,
            }
        );
        my @location_list = ();
        require MT::Asset;
        for my $oa (@non_embedded_assets) {
            my $a = MT::Asset->load( $oa->asset_id ) or next;
            next unless ( $a->isa('GeoType::LocationAsset') );
            my $e = MT::Entry->load( $oa->object_id );
            push @location_list,
                { id => $a->id, name => $a->name, options => ( $e->location_options->{ $a->id } || {} ) };
        }

        $param->{location_list} = \@location_list;
    }
}

sub param_asset_insert {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = $cb->plugin;

    # proceed as normal unless we detect the simple association type
    return 1 unless $app->param('edit_field') eq 'location_list';

    my $block = $tmpl->getElementById('insert_script');
    return 1 unless $block;
    my $preview_html = '';
    my $ctx          = $tmpl->context;
    if ( my $asset = $ctx->stash('asset') ) {
        my $asset_id   = $asset->id;
        my $asset_name = $asset->name;
        require MT::Util;
        $asset_name = MT::Util::encode_js($asset_name);
        $block->innerHTML(qq{top.insertLocation($asset_id, '$asset_name');});
    }
}

sub post_save_entry {
    my ( $cb, $app, $entry ) = @_;

    my %locations;
    my $location_list = $app->param('location_list');
    require JSON;
    my $locations = JSON::jsonToObj($location_list);
    foreach my $loc (@$locations) {
        $locations{ $loc->{id} } = $loc->{options};
    }

#    foreach my $loc (split (/\s*,\s*/, $location_list)) {
#        my ($id, $opts) = split (/\|\|/, $loc, 2);
#        my %opts_hash = map { my ($k, $v) = split (/=/, $_, 2); $k => $v } $opts;
#        $locations{$id} = { %opts_hash };
#    }
    my @ids = keys %locations;

    my @asset_list = MT::Asset->load(
        { class => 'location' },
        {
            join => MT::ObjectAsset->join_on(
                'asset_id',
                {
                    object_id => $entry->id,
                    object_ds => $entry->datasource,
                    embedded  => 0,
                }
            )
        }
    );
    my %asset_ids = map { $_->id => 1 } @asset_list;
    my @new_embeds;

    # first go through & don't re-add anything that's on our list that's already there
    for (@ids) {
        push @new_embeds, $_ unless ( defined $asset_ids{$_} );
        delete $asset_ids{$_} if ( defined $asset_ids{$_} );
    }

    require GeoType::LocationAsset;
    for my $id (@new_embeds) {
        my $la = GeoType::LocationAsset->load($id) or next;
        my $oa = MT::ObjectAsset->set_by_key(
            {
                blog_id   => $entry->blog_id,
                object_id => $entry->id,
                object_ds => $entry->datasource,
                asset_id  => $id,
                embedded  => 0,
            }
        ) or return $cb->error( MT::ObjectAsset->errstr );
    }

    # remove any that got deleted
    for my $id ( keys %asset_ids ) {
        MT::ObjectAsset->remove(
            {
                blog_id   => $entry->blog_id,
                object_id => $entry->id,
                object_ds => $entry->datasource,
                asset_id  => $id
            }
        );
    }

    $entry->location_options( \%locations );
    $entry->save or return $cb->error( $entry->errstr );
    1;
}

sub preview_locations {
    my $app  = shift;
    my $blog = $app->blog;

    my $location_list = $app->param('location_list');
    require JSON;
    my $locations = JSON::from_json($location_list);
    my @ids = map { $_->{id} } @$locations;
    my @locations;
    require MT::Asset;
    for my $id (@ids) {
        next unless $id;
        my $asset = MT::Asset->load($id) or next;
        push @locations, $asset if ( $asset->isa('GeoType::LocationAsset') );
    }

    @locations = map {
        { id => $_->id, name => $_->name, geometry => $_->geometry, lat => $_->latitude, lng => $_->longitude }
    } @locations;

    my $plugin   = MT->component('geotype');
    my $map_type = $plugin->get_config_value( 'interactive_map_type', 'blog:' . $blog->id );
    my $config   = $plugin->get_config_hash( 'blog:' . $blog->id );
    $map_type =
          $map_type eq 'roadmap'   ? 'G_NORMAL_MAP'
        : $map_type eq 'satellite' ? 'G_SATELLITE_MAP'
        : $map_type eq 'hybrid'    ? 'G_HYBRID_MAP'
        : $map_type eq 'terrain'   ? 'G_PHYSICAL_MAP'
        :                            'G_NORMAL_MAP';
    my $key = GeoType::Util::get_google_api_key($blog);
    return $app->load_tmpl(
        'dialog/preview_locations.tmpl',
        {
            map_type       => $map_type,
            google_api_key => $key,
            location_list  => \@locations,
            %$config,
        }
    );
}

sub source_asset_list {
    my ( $cb, $app, $tmpl ) = @_;

    return 1 unless ( $app->param('edit_field') eq 'location_list' );

    my $new = q{
        <img src="<mt:var name="static_uri">images/status_icons/create.gif" alt="<__trans phrase="Add New Location">" width="9" height="9" />
        <mt:unless name="asset_select"><mt:setvar name="entry_insert" value="1"></mt:unless>
        <a href="<mt:var name="script_url">?__mode=create_location&amp;blog_id=<mt:var name="blog_id">&amp;dialog_view=1&amp;entry_insert=1&amp;edit_field=<mt:var name="edit_field" escape="url">&amp;upload_mode=<mt:var name="upload_mode" escape="url">&amp;<mt:if name="require_type">require_type=<mt:var name="require_type">&amp;</mt:if>return_args=<mt:var name="return_args" escape="url"><mt:if name="user_id">&amp;user_id=<mt:var name="user_id" escape="url"></mt:if>" ><__trans phrase="Add New Location"></a>
    };

    $$tmpl
        =~ s{\Q<mt:setvarblock name="upload_new_file_link">\E.*\Q</mt:setvarblock>\E}{<mt:setvarblock name="upload_new_file_link">$new</mt:setvarblock>}ms;
}

sub location_options {
    my $app  = shift;
    my $blog = $app->blog;

    my $loc = $app->param('location');

    # my ($id, $options) = split (/\|\|/, $loc, 2);
    my $id      = $app->param('location_id');
    my $options = $app->param('location_options');

    require JSON;
    $options = JSON::from_json($options);

    require MT::Asset;
    my $location = MT::Asset->load($id);

    my $location_hash = {
        id       => $location->id,
        name     => $location->name,
        geometry => $location->geometry,
        lat      => $location->latitude,
        lng      => $location->longitude,
        options  => $options
    };
    $location_hash->{options}->{contents} ||= $location->description;

#    my $location_opts = { map { "location_marker_opt_$_" => $options->{$_} } keys %$options };
#    $location_opts->{location_marker_opt_contents} ||= $location->description;

    my $plugin   = MT->component('geotype');
    my $map_type = $plugin->get_config_value( 'interactive_map_type', 'blog:' . $blog->id );
    my $config   = $plugin->get_config_hash( 'blog:' . $blog->id );
    $map_type =
          $map_type eq 'roadmap'   ? 'G_NORMAL_MAP'
        : $map_type eq 'satellite' ? 'G_SATELLITE_MAP'
        : $map_type eq 'hybrid'    ? 'G_HYBRID_MAP'
        : $map_type eq 'terrain'   ? 'G_PHYSICAL_MAP'
        :                            'G_NORMAL_MAP';
    my $key = GeoType::Util::get_google_api_key($blog);

    return $app->load_tmpl(
        'dialog/location_options.tmpl',
        {
            location       => $location_hash,
            map_type       => $map_type,
            google_api_key => $key,
            %$config,
            %{ $location_hash->{options} },

            # %$location_opts,
        }
    );
}

1;

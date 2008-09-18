
package GeoType::LocationAsset;

use strict;
use warnings;

use base qw( MT::Asset );

__PACKAGE__->install_properties ({
    class_type  => 'location',
    column_defs => {
        'lattitude' => 'string meta',
        'longitude' => 'string meta',
        'basename' => 'string meta',
        # 'visible' => 'integer not null default 1 meta'
    }
});

sub name {
    return shift->label (@_);
}

sub location {
    return shift->description (@_);
}

sub class_label {
    MT->translate ('Location');
}

sub class_label_plural {
    MT->translate ('Locations');
}

sub geometry {
    my $obj = shift;
    return join (",", $obj->lattitude, $obj->longitude);
}

sub has_thumbnail { 1; }
sub on_upload     { 1; }

sub thumbnail_url {
    my $obj = shift;
    my (%params) = @_;
    
    require GeoType::Util;
    return GeoType::Util::static_url_for_locations (\%params, $obj);
}

sub url {
    my $obj = shift;
    my (%params) = @_;
    
    require GeoType::Util;
    return GeoType::Util::static_url_for_locations (\%params, $obj);
}

sub as_html {
    my $obj = shift;
    my ($params) = @_;
    
    my $text = sprintf '<img src="%s" title="%s"/>',
        MT::Util::encode_html($obj->url (%$params)),
        MT::Util::encode_html($obj->name);
    return $obj->enclose ($text);
}

sub insert_options {
    my $asset = shift;
    my ($param) = @_;

    return unless $param->{edit_field} ne 'location_list';

    my $app   = MT->instance;
    my $perms = $app->{perms};
    my $blog  = $asset->blog or return;
    my $plugin = MT->component ('geotype');
    
    $param->{MapType} = $plugin->get_config_value ('default_map_type', 'blog:' . $blog->id);
    $param->{Height}   = $plugin->get_config_value ('map_height', 'blog:' . $blog->id);
    $param->{Width}    = $plugin->get_config_value ('map_width', 'blog:' . $blog->id);
    $param->{marker_color} = '';
    $param->{marker_size}  = '';
    $param->{marker_char}  = '';

    my $tmpl = $plugin->load_tmpl ('dialog/location_insert_options.tmpl', $param) or MT->log ($plugin->errstr);
    my $html = $app->build_page($tmpl, $param );
    if (!$html) {
        MT->log ($app->errstr);
    }
    return $html;
}


1;

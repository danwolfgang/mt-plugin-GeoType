package GeoPress::App;
use strict;

use MT::App;
@GeoPress::App::ISA = qw( MT::App );

use MT::App::CMS;
use GeoPress::Location;
use GeoPress::EntryLocation;

# Useful tutorial: http://www.movalog.com/archives/plugins/walkthrough/movable-type-plugin-walkthrough-interfaces
sub init {
	my $app = shift;
	$app->SUPER::init(@_) or return;
	$app->add_methods(
		'view'              => \&list_locations,
		'map'              => \&configure_map,
		'save_map' 			 => \&save_configure_map,
		'save_locations' 			 => \&save_locations,
		'widget'            => \&create_widget,
		'save_widget'       => \&save_widget,
		);
	$app->{default_mode} = 'map';
	$app->{requires_login} = 1;
	$app;

}

sub save_configure_map {
    my $app = shift;
    my $q = $app->{query};

    my $blog_id = $q->param('blog_id');
		my $plugin = MT::Plugin::GeoPress->instance;
		my %param;
		my @params = $q->param;
    foreach (@params) {
         next if $_ =~ m/^(__mode|return_args|plugin_sig|magic_token|blog_id)$/;
         $param{$_} = $q->param($_);
     }
     if ($plugin) {
         $plugin->save_config(\%param, $blog_id ? 'blog:' . $blog_id : 'system');
     }
 
		configure_map($app);
}
sub configure_map {
	my $app = shift;
	my $q = $app->{query};
	my $plugin = MT::Plugin::GeoPress->instance;
	my $param = { };

	my $blog_id = $q->param('blog_id');
	my $blog = $app->blog;
	my $sytem_config = $plugin->get_config_hash('system');
	my $config = $plugin->get_config_hash('blog:' . $blog_id);
	my $apppath = $app->{__path} || "";
	my $map_param = { };

	# Build up the keys
    $map_param->{google_api_key} = $plugin->get_google_api_key ($blog);
    $map_param->{yahoo_api_key} = $plugin->get_yahoo_api_key ($blog);

	my $microsoft_map = $sytem_config->{microsoft_map};	
	if($microsoft_map)  {$map_param->{microsoft_map} = $microsoft_map; }
	my $map_tmpl = $app->build_page('geopress_header.tmpl', $map_param);

	$param->{blog_id} = $blog_id;
	$param->{can_post} = 1;
	$param->{has_posting_label} = 1;
	$app->add_breadcrumb('Main Menu', $app->{mt_url});
	$app->add_breadcrumb('GeoPress', $app->uri('mode' => 'map', args => { 'text' => $param->{text}} ));
	$app->add_breadcrumb('Configure Maps');
	$param->{breadcrumbs} = $app->{breadcrumbs};
	$param->{breadcrumbs}[-1]{is_last} = 1;

	# Get all of the plugin config options
	foreach (keys %$config){
		$param->{$_} = $config->{$_};
	}
	$param->{'default_zoom_level_'.$config->{default_zoom_level}} = 1;
	$param->{'default_map_type_'.$config->{default_map_type}} = 1;
	$param->{'default_map_format_'.$config->{default_map_format}} = 1;
	$param->{'map_controls_zoom_'.$config->{map_controls_zoom}} = 1;

	my $tmpl = $app->build_page('configure_map.tmpl', $param);

	my ($old, $new);
	$old = qq{</head>};
	$old = quotemeta($old);
	$tmpl =~ s/($old)/$map_tmpl\n$1\n/;
	return $tmpl;
}

sub save_locations {
    my $app = shift;
    my $q = $app->{query};

    my $blog_id = $q->param('blog_id');
	my $plugin = MT::Plugin::GeoPress->instance;
	my %param;
	my @params = $q->param;

	my $index = 0;
	while($index < $q->param('num_locations')) {
		my $locid = $q->param('locid['.$index.']');
		my $location = GeoPress::Location->get_by_key({ id => $locid });		
		$location->location( $q->param('locaddr['.$index.']') );
		$location->name( $q->param('locname['.$index.']') );
		$location->geometry( $q->param('location_geometry['.$index.']') );
		$location->visible( $q->param('locvisible['.$index.']')  ? 1 : 0 ); 
		$location->save or die "Saving location failed: ", $location->errstr;
		$index++;
	}
 
	list_locations($app);
}

sub list_locations {
	my $app = shift;
	my $q = $app->{query};
	my $plugin = MT::Plugin::GeoPress->instance;
	my $param = { };

	my $blog_id = $q->param('blog_id');
	my $blog = $app->blog;
	my $system_config = $plugin->get_config_hash('system');
	my $config = $plugin->get_config_hash('blog:' . $blog_id);
	my $apppath = $app->{__path} || "";
	my $map_param = { };

	# Build up the keys
	$map_param->{google_api_key} = $plugin->get_google_api_key ($blog);
	$map_param->{yahoo_api_key} = $plugin->get_yahoo_api_key ($blog);

	my $microsoft_map = $system_config->{microsoft_map};	
	if($microsoft_map)  {$map_param->{microsoft_map} = $microsoft_map; }
	my $map_tmpl = $app->build_page('geopress_header.tmpl', $map_param);

	$param->{blog_id} = $blog_id;
	$param->{can_post} = 1;
	$param->{has_posting_label} = 1;
	$app->add_breadcrumb('Main Menu', $app->{mt_url});
	$app->add_breadcrumb('GeoPress', $app->uri('mode' => 'map', args => { 'text' => $param->{text}} ));
	$app->add_breadcrumb('Edit Locations');
	$param->{breadcrumbs} = $app->{breadcrumbs};
	$param->{breadcrumbs}[-1]{is_last} = 1;

	# 
	# my $data = $app->build_location_table( param => \%param );
	# delete $param{location_table} unless @$data;

	my @data;
	my @locations = GeoPress::Location->load({ blog_id => $blog_id });
	my $i = 0;
	foreach $GeoPress::App::location(@locations) {
		my $row = {
			location_index => $i,
			location_id => $GeoPress::App::location->id,
			location_name => $GeoPress::App::location->name,
			location_location => $GeoPress::App::location->location,
			location_geometry => $GeoPress::App::location->geometry,
			location_visible => $GeoPress::App::location->visible
		};
		$i++;
		push @data, $row;
	}
	$param->{num_locations} = $i;
	$param->{location_table}[0]{object_loop} = \@data;
	# $app->load_itemset_actions('location', $param->{location_table}[0]);


	my $tmpl = $app->build_page('list.tmpl', $param);

	my ($old, $new);
	$old = qq{</head>};
	$old = quotemeta($old);
	$tmpl =~ s/($old)/$map_tmpl\n$1\n/;
	return $tmpl;
}

1;

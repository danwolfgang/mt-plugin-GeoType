package GeoType::Plugin;

use base qw( MT::Plugin );

sub plugin {
    return MT->component('GeoType');
}

sub load_config {
	my $plugin = shift;
    my ($args, $scope) = @_;

    $plugin->SUPER::load_config(@_);

	if ($scope =~ m/blog:(\d+)/) {
		my $blog_id = $1;

		my $default_location = $plugin->get_config_value('default_location', $scope);
		
		if ($default_location) { # this is stored as ('location', 'latitude', 'longitude')
			$args->{default_location_address} = @$default_location[0];
		}
	}
}

sub save_config {
	my $plugin = shift;
	my ($param, $scope) = @_;
	
	if ($scope =~ m/blog:(\d+)/) {
		my $blog_id = $1;
		my $blog = MT::Blog->load($blog_id);
		my $dla = $param->{default_location_address};
		require GeoType::Util;
		my @default_location = GeoType::Util::geocode($blog, $dla);
		unshift @default_location, $dla;
		$param->{default_location} = \@default_location;
	}
	
    return $plugin->SUPER::save_config(@_);
}

1;
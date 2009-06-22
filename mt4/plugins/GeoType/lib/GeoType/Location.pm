package GeoType::Location;
use strict;

use base qw(MT::Object);
use GeoType::Util;
use GeoType::EntryLocation;
use GeoType::ExtendedLocation;

__PACKAGE__->install_properties({
	column_defs => {
	        'id' => 'integer not null auto_increment',
	        'blog_id' => 'integer not null',
	        'name' => 'string(255)',
	        'location' => 'string(255)',
	        'mapurl' => 'string(255)',
	        'geometry' => 'text',
	        'basename' => 'string(255)',
	        'visible' => 'integer not null default 1'
	},
    indexes => {
        name => 1,
        blog_id => 1
    },
    datasource => 'location',
    primary_key => 'id',
    audit => 1,
    
    child_classes => [ 'GeoType::EntryLocation', 'GeoType::ExtendedLocation' ],
});

sub remove {
    my $location = shift;
    
    require MT::Request;
    my $r = MT::Request->instance;
    my @objs = GeoType::EntryLocation->load ({ location_id => $location->id });
    $r->cache ('entry_location_objs', [ @objs ]);
    
    $location->remove_children ({ key => 'location_id' });
    $location->SUPER::remove (@_);
}

sub save {
    my $l = shift;
    if (!defined($l->basename) || ($l->basename eq '')) {
        my $name = GeoType::Util::make_location_basename($l);
        $l->basename($name);
    }
    $l->SUPER::save(@_);
}

sub make_guid {
    my $l = shift;
    my $blog = MT::Blog->load($l->blog_id);
    die "Unable to load blog " . $l->blog_id unless $blog;
	my ($host, $year, $path, $blog_id, $basename);
    $blog_id = $l->blog_id;
    $basename = $l->basename;
    die "No basename for location " . $l->id unless $basename;
    my $url = $blog->site_url || '';
    $url .= '/' unless $url =~ m!/$!;
    if ($url && ($url =~ m!^https?://([^/:]+)(?::\d+)?(/.*)$!)) {
        $host = $1;
        $path = $2;
    }
    if ($l->created_on && ($l->created_on =~ m/^(\d{4})/)) {
        $year = $1;
    }
    return '' unless $host && $year && $path && $blog_id && $basename;
    qq{tag:$host,$year:$path/$blog_id.loc.$basename};
}

1;

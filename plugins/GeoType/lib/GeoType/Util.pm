package GeoType::Util;
use strict;

use Exporter;
@MT::Util::ISA = qw( Exporter );

use MT::Blog;
use MT::Util;

sub make_location_basename {
    my ($l) = @_;
    my $blog_id = $l->blog_id;
    my $blog = MT::Blog->load( $blog_id );
    $blog or die "Blog #$blog_id cannot be loaded.";
    my $location = $l->location; # "1600 Pennsylvania Ave NW, Washington DC", e.g.
    $location = '' if !defined $location;
    $location =~ s/^\s+|\s+$//gs;
    $location = 'location' if $location eq '';
    my $limit = $blog->basename_limit || 30; # FIXME
    $limit = 15 if $limit < 15; $limit = 250 if $limit > 250;
    my $base = substr(MT::Util::dirify($location), 0, $limit);
    $base =~ s/_+$//;
    $base = 'location' if $base eq '';
    my $i = 1;
    my $base_copy = $base;
    while (GeoType::Location->count({ blog_id => $blog->id,
                              basename => $base })) {
        $base = $base_copy . '_' . $i++;
    }
    $base;
}



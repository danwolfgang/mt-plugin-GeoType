package GeoType::App;

use strict;
use base 'MT::App';
use GeoType::Location;
use GeoType::EntryLocation;
use vars qw($VERSION);

$VERSION = '1.0';

sub init {
    my $app = shift;
    $app->SUPER::init(@_) or return;
    $app->add_methods(
        all => \&sorted_locations_feed,
        sorted => \&all_locations_feed,
    );
    $app->{default_mode} = 'all';
    $app->{requires_login} = 0;
    $app;
}

sub init_request {
    my $app = shift;
    $app->SUPER::init_request(@_);
}

sub sorted_locations_feed {
	my ($app) = @_;
	require MT::Template;
	require MT::Builder;
	require MT::Template::Context;

	my $blog_id = $app->param ('blog_id');
	return $app->error ("Blog ID parameter not provided\n")
		unless $blog_id;
	my $blog = MT::Blog->load( $blog_id );
	return $app->error ("Blog $blog_id not found\n")
		unless $blog_id;
	my $offset = $app->param ('offset');
	$offset ||= 0;
	my $limit = $app->param ('limit');
	$limit ||= 50;
	my $iter = GeoType::Location->load_iter({
	}, { 'join' => ['GeoType::EntryLocation', 'location_id',
						{ blog_id => $blog_id },
						{'sort' => 'entry_id',
						direction => 'descend',
						unique => 1
						}],
		ofset => $offset,
		limit => $limit,
	});
	my @locations;
	while ( my $l = $iter->() ) {
		push @locations, $l;
	}
	my $param;
        my $tmpl = MT::Template->load({name => 'Atom Locations Feed' });
	return $app->error("Atom Locations Feed not found")
		unless ( $tmpl );
	my $ctx = MT::Template::Context->new;
	$ctx->stash('blog', $blog);
	$ctx->stash('blog_id', $blog_id);
	$ctx->stash('locations', \@locations);
	my $build = MT::Builder->new;
        my $preview_code = $tmpl->text;
        my $tokens = $build->compile($ctx, $preview_code)
                or return $app->error($app->translate(
                 "Parse error: [_1]", $build->errstr));
	defined(my $html = $build->build($ctx, $tokens))
		or return $app->error($app->translate(
		"Build error: [_1]", $build->errstr));
	return $html;
}

sub all_locations_feed {
	my ($app) = @_;
	require MT::Template;
	require MT::Builder;
	require MT::Template::Context;

	my $blog_id = $app->param ('blog_id');
	return $app->error ("Blog ID parameter not provided\n")
		unless $blog_id;
	my $blog = MT::Blog->load( $blog_id );
	return $app->error ("Blog $blog_id not found\n")
		unless $blog_id;
	my $offset = $app->param ('offset');
	$offset ||= 0;
	my $limit = $app->param ('limit');
	$limit ||= 50;
	my $iter = GeoType::Location->load_iter({
		blog_id => $blog_id
	}, { sort => 'id', direction => 'ascend', offset => $offset, limit => $limit } );
	my @locations;
	while ( my $l = $iter->() ) {
		push @locations, $l;
	}
	my $param;
        my $tmpl = MT::Template->load({name => 'Atom Locations Feed' });
	return $app->error("Atom Locations Feed not found")
		unless ( $tmpl );
	my $ctx = MT::Template::Context->new;
	$ctx->stash('blog', $blog);
	$ctx->stash('blog_id', $blog_id);
	$ctx->stash('locations', \@locations);
	my $build = MT::Builder->new;
        my $preview_code = $tmpl->text;
        my $tokens = $build->compile($ctx, $preview_code)
                or return $app->error($app->translate(
                 "Parse error: [_1]", $build->errstr));
	defined(my $html = $build->build($ctx, $tokens))
		or return $app->error($app->translate(
		"Build error: [_1]", $build->errstr));
	return $html;
}

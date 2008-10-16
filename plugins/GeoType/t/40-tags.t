
use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';

use MT::Test qw( :db :data );
use Test::More tests => 13;
use Test::Exception;

require MT::Template::Context;
my $ctx = MT::Template::Context->new;

ok ($ctx->handler_for ("geotype:$_"), "GeoType:$_ exists") foreach (qw( map entrymap assetmap archivemap mapheader ));

my $entry_ctx = MT::Template::Context->new;
require MT::Entry;
$entry_ctx->stash ('entry', MT::Entry->load (1));

my $archive_ctx = MT::Template::Context->new;
require MT::ArchiveType::Monthly;
$archive_ctx->{current_archive_type} = 'Monthly';
$archive_ctx->stash ('entries', [ MT::Entry->load ({ blog_id => 1, status => MT::Entry::RELEASE() }) ]);

my $non_location_asset_ctx = MT::Template::Context->new;
$non_location_asset_ctx->stash ('asset', MT::Asset->load (1));

require MT::Template;
my $tmpl = MT::Template->new;
$tmpl->blog_id ('1');

$tmpl->text ('<mt:geotype:map>');
$tmpl->reset_tokens;
is ($tmpl->build (MT::Template::Context->new), undef, "Map with no context errors out");
is ($tmpl->build ($entry_ctx), '', "Map with entry context, but no locations");
is ($tmpl->build ($archive_ctx), '', "Map with archive context, but no locations");
is ($tmpl->build ($non_location_asset_ctx), '', "Map with asset context, but no locations");

$tmpl->text ('<mt:geotype:map lastnentries="5">');
$tmpl->reset_tokens;
is ($tmpl->build (MT::Template::Context->new), '', "Map with lastnentries, but no locations");

$tmpl->text ('<mt:geotype:entrymap>');
$tmpl->reset_tokens;
is ($tmpl->build (MT::Template::Context->new), undef, "Entry map with no entry context");
is ($tmpl->build ($entry_ctx), '', "Entry map with entry context, but no locations");

use Data::Dumper;
print Dumper (MT->publisher->archiver ('Monthly'));

$tmpl->text ('<mt:geotype:archivemap>');
$tmpl->reset_tokens;
# this test is iffy, since it dies instead of erroring out
# is ($tmpl->build (MT::Template::Context->new), undef, "Archive map with no archive context");
is ($tmpl->build ($archive_ctx), '', "Archive map with archive context, but no locations");

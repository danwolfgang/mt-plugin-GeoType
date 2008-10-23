
use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';

use MT::Test qw( :db :data );
use Test::More tests => 26;
use Test::Exception;

# setup api key
use MT;
my $plugin = MT->component ('geotype');
$plugin->set_config_value ('google_api_key', 'abcdefg', 'blog:1');

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

require MT::Blog;
require_ok ('GeoType::Util');
my $location_asset = GeoType::Util::asset_from_address (MT::Blog->load (1), "1600 Amphitheatre Parkway, Mountain View, CA", "Google HQ");
ok ($location_asset->save, "Saved location asset");

require MT::ObjectAsset;
ok (MT::ObjectAsset->set_by_key ({ blog_id => 1, object_ds => 'entry', object_id => 1, asset_id => $location_asset->id, embedded => 0 }), "Created asset assocation");

my $asset_ctx = MT::Template::Context->new;
$asset_ctx->stash ('asset', $location_asset);

$tmpl->text ('<mt:geotype:map>');
$tmpl->reset_tokens;
my $res = $tmpl->build ($asset_ctx);
isnt ($res, undef, "Map with asset context didn't error out");
isnt ($res, '', "Map with asset context didn't return empty");

$res = $tmpl->build ($entry_ctx);
isnt ($res, undef, "Map with entry context didn't error out");
isnt ($res, '', "Map with entry context didn't return empty");

$res = $tmpl->build ($archive_ctx);
isnt ($res, undef, "Map with archive context didn't error out");
isnt ($res, '', "Map with archive context didn't return empty");

$tmpl->text ('<mt:geotype:map lastnentries="5">');
$tmpl->reset_tokens;
$res = $tmpl->build (MT::Template::Context->new);
isnt ($res, undef, "Map with lastnentries didn't error out");
isnt ($res, '', "Map with lastnentries didn't return empty");

$tmpl->text ('<mt:geotype:map static="1">');
$tmpl->reset_tokens;
$res = $tmpl->build ($asset_ctx);
isnt ($res, undef, "Map with asset context didn't error out");
isnt ($res, '', "Map with asset context didn't return empty");

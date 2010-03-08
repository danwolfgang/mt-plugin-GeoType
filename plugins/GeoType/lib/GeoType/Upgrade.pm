
package GeoType::Upgrade;

use strict;
use warnings;

sub location_to_asset {
    require GeoType::Location;
    require GeoType::LocationAsset;

    my %location_id_to_asset_id = ();

    foreach my $loc (GeoType::Location->load) {
        my $la = GeoType::LocationAsset->new;
        $la->blog_id ($loc->blog_id);
        $la->geometry ($loc->geometry);
        $la->name ($loc->name);
        $la->location ($loc->location);

        $la->save or die $la->errstr;

        $location_id_to_asset_id{$loc->id} = $la->id;
    }

    require GeoType::EntryLocation;
    require MT::Entry;
    require MT::ObjectAsset;

    foreach my $entry_loc (GeoType::EntryLocation->load) {
        my $e = MT::Entry->load ($entry_loc->entry_id) or next;

        next unless $location_id_to_asset_id{$entry_loc->location_id};

        my $oa = MT::ObjectAsset->set_by_key ({
            blog_id     => $e->blog_id,
            object_ds   => 'entry',
            object_id   => $e->id,
            asset_id    => $location_id_to_asset_id{$entry_loc->location_id},
            embedded    => 0,
        }) or die MT::ObjectAsset->errstr;
    }
}


1;

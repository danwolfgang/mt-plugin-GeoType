##########################################################################
# Copyright C 2007-2010 Six Apart Ltd.
# This program is free software: you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# version 2 for more details.  You should have received a copy of the GNU
# General Public License version 2 along with this program. If not, see
# <http://www.gnu.org/licenses/>.
# CMS.pm 20010-03-08  nataliepo

package GeoType::Upgrade;

use strict;
use warnings;

sub location_to_asset {
    require GeoType::Location;
    require GeoType::LocationAsset;

    my %location_id_to_asset_id = ();

    foreach my $loc ( GeoType::Location->load ) {
        my $la = GeoType::LocationAsset->new;
        $la->blog_id( $loc->blog_id );
        $la->geometry( $loc->geometry );
        $la->name( $loc->name );
        $la->location( $loc->location );

        $la->save or die $la->errstr;

        $location_id_to_asset_id{ $loc->id } = $la->id;
    }

    require GeoType::EntryLocation;
    require MT::Entry;
    require MT::ObjectAsset;

    foreach my $entry_loc ( GeoType::EntryLocation->load ) {
        my $e = MT::Entry->load( $entry_loc->entry_id ) or next;

        next unless $location_id_to_asset_id{ $entry_loc->location_id };

        my $oa = MT::ObjectAsset->set_by_key(
            {
                blog_id   => $e->blog_id,
                object_ds => 'entry',
                object_id => $e->id,
                asset_id => $location_id_to_asset_id{ $entry_loc->location_id },
                embedded => 0,
            }
        ) or die MT::ObjectAsset->errstr;
    }
}

1;

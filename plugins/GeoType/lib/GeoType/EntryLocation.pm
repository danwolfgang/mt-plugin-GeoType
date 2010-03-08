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

package GeoType::EntryLocation;
use strict;

use base qw(MT::Object);

__PACKAGE__->install_properties(
    {
        column_defs => {
            'id'          => 'integer not null auto_increment',
            'blog_id'     => 'integer not null',
            'entry_id'    => 'integer not null',
            'location_id' => 'integer not null',
            'zoom_level'  => 'smallint',
        },
        indexes => {
            entry_id    => 1,
            blog_id     => 1,
            location_id => 1
        },
        datasource  => 'entrylocation',
        primary_key => 'id',
        child_of    => 'MT::Entry',
    }
);

1;

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

package GeoType::ExtendedLocation;
use strict;

use base qw(MT::Object);

__PACKAGE__->install_properties(
    {
        column_defs => {
            'id'           => 'integer not null auto_increment',
            'location_id'  => 'integer not null',
            'cross_street' => 'string(255)',
            'phone_number' => 'string(255)',
            'hours'        => 'string(255)',
            'url'          => 'string(255)',
            'thumbnail'    => 'string(255)',
            'rating'       => 'float',
            'description'  => 'text',
            'place_id'     => 'string(255)'
        },
        indexes     => { location_id => 1 },
        datasource  => 'extendedlocation',
        primary_key => 'id'
    }
);

1;

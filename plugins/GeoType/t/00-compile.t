##########################################################################
# Copyright C 2007-2010 Six Apart Ltd.
# This program is free software: you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# version 2 for more details. You should have received a copy of the GNU
# General Public License version 2 along with this program. If not, see
# <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use lib 't/lib', 'lib', 'extlib';
use Test::More tests => 3;
use MT::Test qw( :db );
use MT;

ok( MT->component('geotype'), "Plugin loaded fine" );

require MT::Entry;
ok( MT::Entry->has_column('location_options'),     "Added location_options column to entry table" );
ok( MT::Entry->is_meta_column('location_options'), "location_options is a meta column" );

# GeoType Plugin

## About
GeoType is a plugin for Movable Type that uses the GoogleMaps API to tie geographic coordinates to an MT object.

## Platform
This release of GeoType is intended for Movable Type 4.3X, although it has similar functionality to the original (http://plugins.movabletype.org/geotype/) plugin on MT3.  

It has not been tested in MT5. Since it modifies several visual elements of the Edit Entry screen in MT4, there is a good chance that it will not work as expected.

## Installation
When installed properly, GeoType will trigger an MT Upgrade screen, since it stores location data along with created entries in the database.

To install this plugin, place the

	plugins/GeoType

directory in your MT plugins directory, and place the

    mt-static/plugins/GeoType

directory in your mt-static/plugins/ directory.

Once the code is in place, you can either start the upgrade in your browser by visiting the URL to log into MT, or you can run it at the command line:

    # where MT_DIR is the path where your MT installation exists (ie where mt.cgi lives)
    cd MT_DIR 
  
    # where adminuser is the username of a Sys Admin user on that mt installation
    perl tools/upgrade --name="adminuser"


## Usage

### Creating a Location
Go to Create -> Location.  Enter an address (ie 700 Pennsylvania Avenue, Washington DC), and press 'GeoCode'.  Provide a custom label for the location in the next step.

### Adding a Location to an Entry
In the Edit Entry screen, there should be a Locations heading in the right sidebar.  Add a location to the entry just as you'd add any other asset.


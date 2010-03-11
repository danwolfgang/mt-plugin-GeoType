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


## Configuration
Before you can interact with the GoogleMap API, you need to set the Google API key. Since you'll need one API key per domain, if all of your blogs publish on the same domain that your MT instance resides on, you only have to set this value in the system-level GeoType plugin settings.  Otherwise, you have to specify the Google API key under each blog's GeoType plugin settings.  

Either way, when you view the GeoType plugin settings, the first input field should be for the API key value, with a link to the Google Maps API registration underneath.  Click on that API Registration link, check the box to agree to the terms, enter your URL, and generate your API key.  Copy and paste the resulting key back into the GeoType plugin settings and save.  

## Usage

### Creating a Location
Go to Create -> Location.  Enter an address (ie 700 Pennsylvania Avenue, Washington DC), and press 'GeoCode'.  Provide a custom label for the location in the next step.

### Adding a Location to an Entry
In the Edit Entry screen, there should be a Locations heading in the right sidebar.  Add a location to the entry just as you'd add any other asset.

### Using the Template Tags
I recommend using the <$MTgeotype:entrymap$> tag in an entry's context to show one map per entry.  Add that tag in the body of your Entry Archive to quickly display your map!


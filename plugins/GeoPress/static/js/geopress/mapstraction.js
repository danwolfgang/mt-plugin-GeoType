/*
   Copyright (c) 2006-7, Tom Carden, Steve Coast, Mikel Maron, Andrew Turner
   All rights reserved.

   Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of the Mapstraction nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


// Use http://jsdoc.sourceforge.net/ to generate documentation

//////////////////////////// 
//
// utility to functions, TODO namespace or remove before release
//
///////////////////////////

/**
 * $, the dollar function, elegantising getElementById()
 * @returns an element
 */
function $() {
  var elements = new Array();
  for (var i = 0; i < arguments.length; i++) {
    var element = arguments[i];
    if (typeof element == 'string')
      element = document.getElementById(element);
    if (arguments.length == 1)
      return element;
    elements.push(element);
  }
  return elements;
}

/**
 * loadScript is a JSON data fetcher 
 */
function loadScript(src,callback) {
  var script = document.createElement('script');
  script.type = 'text/javascript';
  script.src = src;
  if (callback) {
    var evl=new Object();
    evl.handleEvent=function (e){callback();};
    script.addEventListener('load',evl,true);
  }
  document.getElementsByTagName("head")[0].appendChild(script);
  return;
}

function convertLatLonXY_Yahoo(point,level){ //Mercator
  var size = 1 << (26 - level);
  var pixel_per_degree = size / 360.0;
  var pixel_per_radian = size / (2 * Math.PI);
  var origin = new YCoordPoint(size / 2 , size / 2);
  var answer = new YCoordPoint();
  answer.x = Math.floor(origin.x + point.lon * pixel_per_degree);
  var sin = Math.sin(point.lat * Math.PI / 180.0);
  answer.y = Math.floor(origin.y + 0.5 * Math.log((1 + sin) / (1 - sin)) * -pixel_per_radian);
  return answer;
}



/**
 *
 */
function loadStyle(href) {
  var link = document.createElement('link');
  link.type = 'text/css';
  link.rel = 'stylesheet';
  link.href = href;
  document.getElementsByTagName("head")[0].appendChild(link);
  return;
}


/**
 * getStyle provides cross-browser access to css
 */
function getStyle(el, prop) {
  var y;
  if (el.currentStyle) 
    y = el.currentStyle[prop];
  else if (window.getComputedStyle)
    y = window.getComputedStyle( el, '').getPropertyValue(prop);
  return y;
}

///////////////////////////// 
//
// Mapstraction proper begins here
//
/////////////////////////////

/**
 * Mapstraction instantiates a map with some API choice into the HTML element given
 * @param {String} element The HTML element to replace with a map
 * @param {String} api The API to use, one of 'google', 'yahoo', 'microsoft', 'openstreetmap', 'multimap', 'map24', 'openlayers', 'mapquest'
 * @constructor
 */
function Mapstraction(element,api) {
  this.api = api; // could detect this from imported scripts?
  this.maps = new Object();
  this.currentElement = $(element);
  this.eventListeners = new Array();
  this.markers = new Array();
  this.polylines = new Array();

  // This is so that it is easy to tell which revision of this file 
  // has been copied into other projects.
  this.svn_revision_string = '$Revision: 123 $';
  this.addControlsArgs = new Object();
  this.addAPI($(element),api);
}

/**
 * swap will change the current api on the fly
 * @param {String} api The API to swap to
 */
Mapstraction.prototype.swap = function(element,api) {
  if (this.api == api) { return; }

  var center = this.getCenter();
  var zoom = this.getZoom();

  this.currentElement.style.visibility = 'hidden';
  this.currentElement.style.display = 'none';


  this.currentElement = $(element);
  this.currentElement.style.visibility = 'visible';
  this.currentElement.style.display = 'block';

  this.api = api;

  if (this.maps[this.api] == undefined) {
    this.addAPI($(element),api);

    this.setCenterAndZoom(center,zoom);

    for (i=0; i<this.markers.length; i++) {
      this.addMarker( this.markers[i], true); 
    }

    for (i=0; i<this.polylines.length; i++) {
      this.addPolyline( this.polylines[i], true); 
    }
  }else{

    //sync the view
    this.setCenterAndZoom(center,zoom);

    //TODO synchronize the markers and polylines too
		// (any overlays created after api instantiation are not sync'd)
  }

  this.addControls(this.addControlsArgs);


}

Mapstraction.prototype.addAPI = function(element,api) { 

  me = this;
  switch (api) {
    case 'yahoo':
      if (YMap) {
        this.maps[api] = new YMap(element);

        YEvent.Capture(this.maps[api],EventsList.MouseClick,function(event,location) { me.clickHandler(location.Lat,location.Lon,location,me) });
        YEvent.Capture(this.maps[api],EventsList.changeZoom,function() { me.moveendHandler(me) });
        YEvent.Capture(this.maps[api],EventsList.endPan,function() { me.moveendHandler(me) });
      }
      else {
        alert('Yahoo map script not imported');
      }
      break;
    case 'google':
      if (GMap2) {
        if (GBrowserIsCompatible()) {
          this.maps[api] = new GMap2(element);

          GEvent.addListener(this.maps[api], 'click', function(marker,location) {
              // If the user puts their own Google markers directly on the map 
              // then there is no location and this event should not fire.
              if ( location ) {
              me.clickHandler(location.y,location.x,location,me);
              }
              });

          GEvent.addListener(this.maps[api], 'moveend', function() {me.moveendHandler(me)});

        }
        else {
          alert('browser not compatible with Google Maps');
        }
      }
      else {
        alert('Google map script not imported');
      }
      break;
    case 'microsoft':
      if (VEMap) {

        element.style.position='relative';

        var msft_width = parseFloat(getStyle($(element),'width'));
        var msft_height = parseFloat(getStyle($(element),'height'));
        /* Hack so the VE works with FF2 */
        var ffv = 0;
        var ffn = "Firefox/";
        var ffp = navigator.userAgent.indexOf(ffn);
        if (ffp != -1) ffv = parseFloat(navigator.userAgent.substring(ffp+ffn.length));
        if (ffv >= 1.5) {
          Msn.Drawing.Graphic.CreateGraphic=function(f,b) { return new Msn.Drawing.SVGGraphic(f,b) }
        }

        this.maps[api] = new VEMap(element.id);
        this.maps[api].LoadMap();

        this.maps[api].AttachEvent("onclick", function(e) { me.clickHandler(e.view.LatLong.Latitude, e.view.LatLong.Longitude, me); });
        this.maps[api].AttachEvent("onchangeview", function(e) {me.moveendHandler(me)});

				//Source of our trouble with Mapufacture?
        this.resizeTo(msft_width, msft_height);
      }
      else {
        alert('Virtual Earth script not imported');
      }
      break;
    case 'openlayers':
      this.maps[api] = new OpenLayers.Map(element.id);
      break;
    case 'openstreetmap':
      // for now, osm is a hack on top of google

      if (GMap2) {
        if (GBrowserIsCompatible()) {
          this.maps[api] = new GMap2(element);

          GEvent.addListener(this.maps[api], 'click', function(marker,location) {
              // If the user puts their own Google markers directly on the map 
              // then there is no location and this event should not fire.
              if ( location ) {
              me.clickHandler(location.y,location.x,location,me);
              }
              });

          GEvent.addListener(this.maps[api], 'moveend', function() {me.moveendHandler(me)});

          // Add OSM tiles

          var copyright = new GCopyright(1, new GLatLngBounds(new GLatLng(-90,-180), new GLatLng(90,180)), 0, "copyleft"); 
          var copyrightCollection = new GCopyrightCollection('OSM'); 
          copyrightCollection.addCopyright(copyright); 

          var tilelayers = new Array(); 
          tilelayers[0] = new GTileLayer(copyrightCollection, 11, 15); 
          tilelayers[0].getTileUrl = function (a, b) {
            return "http://tile.openstreetmap.org/"+b+"/"+a.x+"/"+a.y+".png";
          };

          var custommap = new GMapType(tilelayers, new GMercatorProjection(19), "OSM", {errorMessage:"More OSM coming soon"}); 
          this.maps[api].addMapType(custommap); 

          var myPoint = new LatLonPoint(50.6805,-1.4062505);
          this.setCenterAndZoom(myPoint, 11);

          this.maps[api].setMapType(custommap);
        }
        else {
          alert('browser not compatible with Google Maps');
        }
      }
      else {
        alert('Google map script not imported');
      }

      break;
    case 'multimap':
      this.maps[api] = new MultimapViewer( element );

			this.maps[api].addEventHandler( 'click', function(eventType, eventTarget, arg1, arg2, arg3) {
				if (arg1) {
					me.clickHandler(arg1.lat, arg1.lon, me);
				}
			});
			this.maps[api].addEventHandler( 'changeZoom', function(eventType, eventTarget, arg1, arg2, arg3) {
				me.moveendHandler(me);
			});
			this.maps[api].addEventHandler( 'endPan', function(eventType, eventTarget, arg1, arg2, arg3) {
				me.moveendHandler(me);
			});
      break;
    case 'map24':
      this.maps[api] = Map24.Webservices.getMap24Application({AppKey: this.apikey, MapArea: element, MapWidth: 400, MapHeight: 400});
      break;
		case 'mapquest':
			this.maps[api] = new MQTileMap(element);
			// MQEventManager.addListener(this.maps[api],"click",function(event,location) { me.clickHandler(location.Lat,location.Lon,location,me) });
			// MQEventManager.addListener(this.maps[api],"zoomend",function() { me.moveendHandler(me) });
			// MQEventManager.addListener(this.maps[api],"moveend",function() { me.moveendHandler(me) });
			break;	
    default:
      alert(api + ' not supported by mapstraction');
  }

     
  // this.resizeTo(getStyle($(element),'width'), getStyle($(element),'height'));
  // the above line was called on all APIs but MSFT alters with the div size when it loads
  // so you have to find the dimensions and set them again (see msft constructor).
  // FIXME: test if google/yahoo etc need this resize called. Also - getStyle returns
  // CSS size ('200px') not an integer, and resizeTo seems to expect ints

}

/* Resize the current map to the specified width and height
 * (since it is actually on a child div of the mapElement passed
 * as argument to the Mapstraction constructor, the resizing of this
 * mapElement may have no effect on the size of the actual map)
 * 
 * @param {int} width The width the map should be.
 * @param {int} height The width the map should be.
 */
Mapstraction.prototype.resizeTo = function(width,height){
  switch (this.api) {
    case 'yahoo':
      this.maps[this.api].resizeTo(new YSize(width,height));
      break;
    case 'google':
    case 'openstreetmap':
      this.currentElement.style.width = width;
      this.currentElement.style.height = height;
      this.maps[this.api].checkResize();
      break;
    case 'microsoft':
      this.maps[this.api].Resize(width, height);
      break;
		case 'multimap':
			this.currentElement.style.width = width;
			this.currentElement.style.height = height;
			this.maps[this.api].resize();
			break;
		case 'mapquest':
			this.currentElement.style.width = width;
			this.currentElement.style.height = height;
      this.maps[this.api].setSize(new MQSize(width, height));
			break;
  }
}

/////////////////////////
// 
// Event Handling
//
///////////////////////////

Mapstraction.prototype.clickHandler = function(lat,lon, me) { //FIXME need to consolidate some of these handlers... 
  for(var i = 0; i < this.eventListeners.length; i++) {
    if(this.eventListeners[i][1] == 'click') {
      this.eventListeners[i][0](new LatLonPoint(lat,lon));
    }
  }
}

Mapstraction.prototype.moveendHandler = function(me) {
  for(var i = 0; i < this.eventListeners.length; i++) {
    if(this.eventListeners[i][1] == 'moveend') {
      this.eventListeners[i][0]();
    }
  }
}

Mapstraction.prototype.addEventListener = function(type, func) {
  var listener = new Array();
  listener.push(func);
  listener.push(type);
  this.eventListeners.push(listener);
}

////////////////////
//
// map manipulation
//
/////////////////////


/**
 * addControls adds controls to the map. You specify which controls to add in
 * the associative array that is the only argument.
 * addControls can be called multiple time, with different args, to dynamically change controls.
 *
 * args = {
 *     pan:      true,
 *     zoom:     'large' || 'small',
 *     overview: true,
 *     scale:    true,
 *     map_type: true,
 * }
 *
 * @param {args} array Which controls to switch on
 */
Mapstraction.prototype.addControls = function( args ) {

  var map = this.maps[this.api];

  this.addControlsArgs = args;

  switch (this.api) {

    case 'google':
    case 'openstreetmap':
      //remove old controls
      if (this.controls) {
        while (ctl = this.controls.pop()) {
          map.removeControl(ctl);
        }
      } else {
        this.controls = new Array();
      }
      c = this.controls;

      // Google has a combined zoom and pan control.
      if ( args.zoom || args.pan ) {
        if ( args.zoom == 'large' ) {
          c.unshift(new GLargeMapControl());
          map.addControl(c[0]);
        } else {
          c.unshift(new GSmallMapControl());
          map.addControl(c[0]);
        }
      }
      if ( args.map_type ) { c.unshift(new GMapTypeControl()); map.addControl(c[0]); }
      if ( args.scale    ) { c.unshift(new GScaleControl()); map.addControl(c[0]); }
      if ( args.overview ) { c.unshift(new GOverviewMapControl()); map.addControl(c[0]); }
      break;

    case 'yahoo':
      if ( args.pan             ) map.addPanControl();
      else map.removePanControl();
      if ( args.zoom == 'large' ) map.addZoomLong();
      else if ( args.zoom == 'small' ) map.addZoomShort();
      else map.removeZoomScale();
      break;

    case 'openlayers':
      // FIXME - which one should this be?
      map.addControl(new OpenLayers.Control.LayerSwitcher());
      break;

		case 'multimap':
			//FIXME -- removeAllWidgets();  -- can't call addControls repeatedly

			pan_zoom_widget = "MM";
			if (args.zoom && args.zoom == "small") { pan_zoom_widget = pan_zoom_widget + "Small"; }
			if (args.pan) { pan_zoom_widget = pan_zoom_widget + "Pan"; }
			if (args.zoom) { pan_zoom_widget = pan_zoom_widget + "Zoom"; }
			pan_zoom_widget = pan_zoom_widget + "Widget";

			if (pan_zoom_widget != "MMWidget") {
				eval(" map.addWidget( new " + pan_zoom_widget + "() );");
			} 

			if ( args.map_type ) { map.addWidget( new MMMapTypeWidget() ); }
			if ( args.overview ) { map.addWidget( new MMOverviewWidget() ); }			
			break;

    case 'mapquest':
      //remove old controls
      if (this.controls) {
        while (ctl = this.controls.pop()) {
          map.removeControl(ctl);
        }
      } else {
        this.controls = new Array();
      }
      c = this.controls;

      if ( args.pan ) { c.unshift(new MQPanControl()); map.addControl(c[0], new MQMapCornerPlacement(MQMapCorner.TOP_LEFT, new MQSize(0,0))); }
      if ( args.zoom == 'large' ) { c.unshift(new MQLargeZoomControl()); map.addControl(c[0], new MQMapCornerPlacement(MQMapCorner.TOP_LEFT, new MQSize(0,0))); }
      else if ( args.zoom == 'small' ) { c.unshift(new MQZoomControl()); map.addControl(c[0],  new MQMapCornerPlacement(MQMapCorner.BOTTOM_LEFT, new MQSize(0,0))); }
			
			// TODO: Map View Control is wonky
      if ( args.map_type ) { c.unshift(new MQViewControl()); map.addControl(c[0], new MQMapCornerPlacement(MQMapCorner.TOP_RIGHT, new MQSize(0,0))); }
      break;
  }
}


/**
 * addSmallControls adds a small map panning control and zoom buttons to the map
 * Supported by: yahoo, google, openstreetmap, openlayers, multimap, mapquest
 */
Mapstraction.prototype.addSmallControls = function() {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'yahoo':
      map.addPanControl();
      map.addZoomShort();
      this.addControlsArgs.pan = true; 
      this.addControlsArgs.zoom = 'small';
      break;
    case 'google':
    case 'openstreetmap':
      map.addControl(new GSmallMapControl());
      this.addControlsArgs.zoom = 'small';
      break;
    case 'openlayers':
      map.addControl(new OpenLayers.Control.LayerSwitcher());
      break;
    case 'multimap':
      smallPanzoomWidget = new MMSmallPanZoomWidget();
      map.addWidget( smallPanzoomWidget );
      this.addControlsArgs.pan = true; 
      this.addControlsArgs.zoom = 'small';
      break;
		case 'mapquest':
			map.addControl(new MQZoomControl(map));
			map.addControl(new PanControl(map));
      this.addControlsArgs.pan = true; 
      this.addControlsArgs.zoom = 'small';
			break;
  }
}

/**
 * addLargeControls adds a small map panning control and zoom buttons to the map
 * Supported by: yahoo, google, openstreetmap, multimap, mapquest
 */
Mapstraction.prototype.addLargeControls = function() {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'yahoo':
      map.addPanControl();
      map.addZoomLong();
      this.addControlsArgs.pan = true;  // keep the controls in case of swap
      this.addControlsArgs.zoom = 'large';
      break;
    case 'google':
    case 'openstreetmap':
      map.addControl(new GLargeMapControl());
      map.addControl(new GMapTypeControl());
      map.addControl(new GScaleControl()) ;
      map.addControl(new GOverviewMapControl()) ;
      this.addControlsArgs.pan = true; 
      this.addControlsArgs.zoom = 'large';
      this.addControlsArgs.overview = true; 
      this.addControlsArgs.scale = true;
      this.addControlsArgs.map_type = true;
      break;
    case 'multimap':
      panzoomWidget = new MMPanZoomWidget();
      map.addWidget( panzoomWidget );
      this.addControlsArgs.pan = true;  // keep the controls in case of swap
      this.addControlsArgs.zoom = 'large';
		case 'mapquest':
			map.addControl(new MQLargeZoomControl(map));
			map.addControl(new PanControl(map));
			map.addControl(new MQViewControl(map));
      this.addControlsArgs.pan = true; 
      this.addControlsArgs.zoom = 'large';
      this.addControlsArgs.map_type = true; 
			break;
  }
}

/**
 * addMapTypeControls adds a map type control to the map (streets, aerial imagery etc)
 * Supported by: yahoo, google, openstreetmap, multimap, mapquest
 */
Mapstraction.prototype.addMapTypeControls = function() {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'yahoo':
      map.addTypeControl();
      break;
    case 'google':
    case 'openstreetmap':
      map.addControl(new GMapTypeControl());
      break;
		case 'multimap':
			map.addWidget( new MMMapTypeWidget() );
			break;
		case 'mapquest':
			map.addControl(new MQViewControl(map));
			break;
  }
}

/**
 * dragging
 *  enable/disable dragging of the map
 *  (only implemented for yahoo and google)
 * Supported by: yahoo, google, openstreetmap, multimap
 * @param {on} on Boolean
 */
Mapstraction.prototype.dragging = function(on) {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'google':
    case 'openstreetmap':
      if (on) {
        map.enableDragging();
      } else {
        map.disableDragging();
      }
      break;
    case 'yahoo':
      if (on) {
        map.enableDragMap();
      } else {
        map.disableDragMap();
      }
      break;
		case 'multimap':
			if (on) {
				map.setOption("drag","dragmap");
			} else {
				map.setOption("drag","");
			}
			break;
		case 'mapquest':
			map.enableDragging(on);
			break;
  }
}

/**
 * centers the map to some place and zoom level
 * @param {LatLonPoint} point Where the center of the map should be
 * @param {int} zoom The zoom level where 0 is all the way out.
 */
Mapstraction.prototype.setCenterAndZoom = function(point, zoom) {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'yahoo':
      var yzoom = 18 - zoom; // maybe?
      map.drawZoomAndCenter(point.toYahoo(),yzoom);
      break;
    case 'google':
    case 'openstreetmap':
      map.setCenter(point.toGoogle(), zoom);
      break;
    case 'microsoft':
      map.SetCenterAndZoom(point.toMicrosoft(),zoom);
      break;
    case 'openlayers':
      map.setCenter(new OpenLayers.LonLat(point.lng, point.lat), zoom);
      break;
    case 'multimap':
      map.goToPosition( new MMLatLon( point.lat, point.lng ) );
      map.setZoomFactor( zoom );
      break;
    case 'map24':
      var mrcContainer = new Map24.Webservices.Request.MapletRemoteControl(  );
      mrcContainer.push(
          new Map24.Webservices.MRC.SetMapView({
Coordinates: new Map24.Coordinate( point.lon * 60.0, point.lat * 60.0 ),
ClippingWidth: new Map24.Webservices.ClippingWidth(
  { MinimumWidth: 5000 }              
  )
})
          );
      map.Webservices.sendRequest( mrcContainer );
      break;
    case 'mapquest':
			// MapQuest's zoom levels appear to be off by '3' from the other providers for the same bbox
			map.setCenter(new MQLatLng( point.lat, point.lng ), zoom - 3 );
      break;
		default:
      alert(this.api + ' not supported by Mapstraction.setCenterAndZoom');
      }
}


/**
 * addMarker adds a marker pin to the map
 * @param {Marker} marker The marker to add
 * @param {old} old If true, doesn't add this marker to the markers array. Used by the "swap" method
 */
Mapstraction.prototype.addMarker = function(marker,old) {
  var map = this.maps[this.api];
  marker.api = this.api;
  marker.map = this.maps[this.api];
  switch (this.api) {
    case 'yahoo':
      var ypin = marker.toYahoo();
      marker.setChild(ypin);
      map.addOverlay(ypin);
      if (! old) { this.markers.push(marker); }
      break;
    case 'google':
    case 'openstreetmap':
      var gpin = marker.toGoogle();
      marker.setChild(gpin);
      map.addOverlay(gpin);
      if (! old) { this.markers.push(marker); }
      break;
    case 'microsoft':
      var mpin = marker.toMicrosoft();
      marker.setChild(mpin); // FIXME: MSFT maps remove the pin by pinID so this isn't needed?
      map.AddPushpin(mpin);
      if (! old) { this.markers.push(marker); }
      break;
    case 'openlayers':
      //this.map.addPopup(new OpenLayers.Popup("chicken", new OpenLayers.LonLat(5,40), new OpenLayers.Size(200,200), "example popup"));
      break;
    case 'multimap':
			var mmpin = marker.toMultiMap();
			marker.setChild(mmpin);
			map.addOverlay(mmpin);
			if (! old) { this.markers.push(marker); }
      break;
    case 'map24':
      var mrcContainer = new Map24.Webservices.Request.MapletRemoteControl( );
      mrcContainer.push(
          new Map24.Webservices.MRC.DeclareMap24Location({
MapObjectID: "pin" + marker.location.lon + '-' + marker.location.lat,
Coordinate: new Map24.Coordinate( marker.location.lon * 60.0, marker.location.lat * 60.0 ),
LogoURL: "http://www.example.com/example.jpg", // FIXME
SymbolID: 20100
})
          );
      mrcContainer.push(
          new Map24.Webservices.MRC.ControlMapObject({
Control: "ENABLE",
MapObjectIDs:  "pin" + marker.location.lon + '-' + marker.location.lat
})
          );
      map.Webservices.sendRequest( mrcContainer );
      break;
    case 'mapquest':
			var mqpin = marker.toMapQuest();
			marker.setChild(mqpin);
			map.addPoi(mqpin);
			if (! old) { this.markers.push(marker); }
      break;
		default:
      alert(this.api + ' not supported by Mapstraction.addMarker');
      }
}

/**
 * removeMarker removes a Marker from the map
 * @param {Marker} marker The marker to remove
 */
Mapstraction.prototype.removeMarker = function(marker) {
  var map = this.maps[this.api];

  var tmparray = new Array();
  while(this.markers.length > 0){
    current_marker = this.markers.pop();
    if(marker == current_marker) {
      switch (this.api) {
        case 'google':
        case 'openstreetmap':
          map.removeOverlay(marker.proprietary_marker);
          break;
        case 'yahoo':
          map.removeOverlay(marker.proprietary_marker);
          break;
        case 'microsoft':
          map.DeletePushpin(marker.pinID);
          break;
				case 'multimap':
					map.removeOverlay(marker.proprietary_marker);
					break;
				case 'mapquest':
					map.removePoi(marker.proprietary_marker);
					break;
      }
      marker.onmap = false;
      break;
    } else {
      tmparray.push(current_marker);
    }
  }
  this.markers = this.markers.concat(tmparray);
}

/**
 * removeAllMarkers removes all the Markers on a map
 */
Mapstraction.prototype.removeAllMarkers = function() {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'yahoo':
      map.removeMarkersAll();
      break;
    case 'google':
    case 'openstreetmap':
      map.clearOverlays();
      break;
    case 'microsoft':
      map.DeleteAllPushpins();
      break;
    case 'multimap':
      map.removeAllOverlays();
      break;
    case 'mapquest':
      map.removeAllPois();
      break;
  }

  this.markers = new Array(); // clear the mapstraction list of markers too

}


/**
 * Add a polyline to the map
 */
Mapstraction.prototype.addPolyline = function(polyline,old) {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'yahoo':
      ypolyline = polyline.toYahoo();
      polyline.setChild(ypolyline);
      map.addOverlay(ypolyline);
      if(!old) {this.polylines.push(polyline);}
      break;
    case 'google':
    case 'openstreetmap':
      gpolyline = polyline.toGoogle();
      polyline.setChild(gpolyline);
      map.addOverlay(gpolyline);
      if(!old) {this.polylines.push(polyline);}
      break;
    case 'microsoft':
      mpolyline = polyline.toMicrosoft();
      polyline.setChild(mpolyline); 
      map.AddPolyline(mpolyline);
      if(!old) {this.polylines.push(polyline);}
      break;
    case 'openlayers':
      alert(this.api + ' not supported by Mapstraction.addPolyline');
      break;
		case 'multimap':
			mmpolyline = polyline.toMultiMap();
			polyline.setChild(mmpolyline);
			map.addOverlay( mmpolyline );
			if(!old) {this.polylines.push(polyline);}
			break;
		case 'mapquest':
			mqpolyline = polyline.toMapQuest();
			polyline.setChild(mqpolyline);
			map.addOverlay( mqpolyline );
			if(!old) {this.polylines.push(polyline);}
			break;			
    default:
      alert(this.api + ' not supported by Mapstraction.addPolyline');
  }
}

/**
 * Remove the polyline from the map
 */ 
Mapstraction.prototype.removePolyline = function(polyline) {
  var map = this.maps[this.api];

  var tmparray = new Array();
  while(this.polylines.length > 0){
    current_polyline = this.polylines.pop();
    if(polyline == current_polyline) {
      switch (this.api) {
        case 'google':
        case 'openstreetmap':
          map.removeOverlay(polyline.proprietary_polyline);
          break;
        case 'yahoo':
          map.removeOverlay(polyline.proprietary_polyline);
          break;
        case 'microsoft':
          map.DeletePolyline(polyline.pllID);
          break;
				case 'multimap':
					polyline.proprietary_polyline.remove();
					break;
      }
      polyline.onmap = false;
      break;
    } else {
      tmparray.push(current_polyline);
    }
  }
  this.polylines = this.polylines.concat(tmparray);
}

/**
 * Removes all polylines from the map
 */
Mapstraction.prototype.removeAllPolylines = function() {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'yahoo':
      for(var i = 0, length = this.polylines.length;i < length;i++){
        map.removeOverlay(this.polylines[i].proprietary_polyline);
      }
      break;
    case 'google':
    case 'openstreetmap':
      for(var i = 0, length = this.polylines.length;i < length;i++){
        map.removeOverlay(this.polylines[i].proprietary_polyline);
      }
      break;
    case 'microsoft':
      map.DeleteAllPolylines();
      break;
		case 'multimap':
      for(var i = 0, length = this.polylines.length;i < length;i++){
				this.polylines[i].proprietary_polyline.remove();
      }
			break;
		case 'mapquest':
			map.removeAllOverlays();
			break;
    default:
      alert(this.api + ' not supported by Mapstraction.removeAllPolylines');
			
  }
  this.polylines = new Array(); 
}

/**
 * getCenter gets the central point of the map
 * @returns  the center point of the map
 * @type LatLonPoint
 */
Mapstraction.prototype.getCenter = function() {
  var map = this.maps[this.api];

  var point = undefined;
  switch (this.api) {
    case 'yahoo':
      var pt = map.getCenterLatLon();
      point = new LatLonPoint(pt.Lat,pt.Lon);
      break;
    case 'google':
    case 'openstreetmap':
      var pt = map.getCenter();
      point = new LatLonPoint(pt.lat(),pt.lng());
      break;
    case 'microsoft':
      var pt = map.GetCenter();
      point = new LatLonPoint(pt.Latitude,pt.Longitude);
      break;
		case 'multimap':
			var pt = map.getCurrentPosition();
			point = new LatLonPoint(pt.y, pt.x);
			break;
    default:
      alert(this.api + ' not supported by Mapstraction.getCenter');
  }
  return point;
}

/**
 * setCenter sets the central point of the map
 * @param {LatLonPoint} point The point at which to center the map
 */
Mapstraction.prototype.setCenter = function(point) {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'yahoo':
      map.panToLatLon(point.toYahoo());
      break;
    case 'google':
    case 'openstreetmap':
      map.setCenter(point.toGoogle());
      break;
    case 'microsoft':
      map.SetCenter(point.toMicrosoft());
      break;
		case 'multimap':
			map.goToPosition(point.toMultiMap());
			break;
		case 'mapquest':
			map.setCenter(point.toMapQuest());
			break;
    default:
      alert(this.api + ' not supported by Mapstraction.setCenter');
  }
}
/**
 * setZoom sets the zoom level for the map
 * MS doesn't seem to do zoom=0, and Gg's sat goes closer than it's maps, and MS's sat goes closer than Y!'s
 * TODO: Mapstraction.prototype.getZoomLevels or something.
 * @param {int} zoom The (native to the map) level zoom the map to.
 */
Mapstraction.prototype.setZoom = function(zoom) {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'yahoo':
      var yzoom = 18 - zoom; // maybe?
      map.setZoomLevel(yzoom);
      break;
    case 'google':
    case 'openstreetmap':
      map.setZoom(zoom);
      break;
    case 'microsoft':
      map.SetZoomLevel(zoom);
      break;
		case 'multimap':
			map.setZoomFactor(zoom);
			break;
    default:
      alert(this.api + ' not supported by Mapstraction.setZoom');
  }
}
/**
 * autoCenterAndZoom sets the center and zoom of the map to the smallest bounding box
 *  containing all markers
 *
 */
Mapstraction.prototype.autoCenterAndZoom = function() {
  var lat_max = -90;
  var lat_min = 90;
  var lon_max = -180;
  var lon_min = 180;

  for (i=0; i<this.markers.length; i++) {
    lat = this.markers[i].location.lat;
    lon = this.markers[i].location.lon;
    if (lat > lat_max) lat_max = lat;
    if (lat < lat_min) lat_min = lat;
    if (lon > lon_max) lon_max = lon;
    if (lon < lon_min) lon_min = lon;
  }
  this.setBounds( new BoundingBox(lat_min, lon_min, lat_max, lon_max) );
}

/**
 * getZoom returns the zoom level of the map
 * @returns the zoom level of the map
 * @type int
 */
Mapstraction.prototype.getZoom = function() {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'yahoo':
      return 18 - map.getZoomLevel(); // maybe?
    case 'google':
    case 'openstreetmap':
      return map.getZoom();
    case 'microsoft':
      return map.GetZoomLevel();
		case 'multimap':
			return map.getZoomFactor();
    default:
      alert(this.api + ' not supported by Mapstraction.getZoom');
  }
}

/**
 * getZoomLevelForBoundingBox returns the best zoom level for bounds given
 * @param boundingBox the bounds to fit
 * @returns the closest zoom level that contains the bounding box
 * @type int
 */
Mapstraction.prototype.getZoomLevelForBoundingBox = function( bbox ) {
  var map = this.maps[this.api];

  // NE and SW points from the bounding box.
  var ne = bbox.getNorthEast();
  var sw = bbox.getSouthWest();

  switch (this.api) {
    case 'google':
    case 'openstreetmap':
      var gbox = new GLatLngBounds( sw.toGoogle(), ne.toGoogle() );
      var zoom = map.getBoundsZoomLevel( gbox );
      return zoom;
			break;
		case 'multimap':
			var mmlocation = map.getBoundsZoomFactor( sw.toMultiMap(), ne.toMultiMap() );
			var zoom = mmlocation.zoom_factor();
			return zoom;
			break;
    default:
      alert( this.api + ' not supported by Mapstraction.getZoomLevelForBoundingBox' );
  }
}


// any use this being a bitmask? Should HYBRID = ROAD | SATELLITE?
Mapstraction.ROAD = 1;
Mapstraction.SATELLITE = 2;
Mapstraction.HYBRID = 3;

/**
 * setMapType sets the imagery type for the map.
 * The type can be one of:
 * Mapstraction.ROAD
 * Mapstraction.SATELLITE
 * Mapstraction.HYBRID
 * @param {int} type The (native to the map) level zoom the map to.
 */
Mapstraction.prototype.setMapType = function(type) {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'yahoo':
      switch(type) {
        case Mapstraction.ROAD:
          map.setMapType(YAHOO_MAP_REG);
          break;
        case Mapstraction.SATELLITE:
          map.setMapType(YAHOO_MAP_SAT);
          break;
        case Mapstraction.HYBRID:
          map.setMapType(YAHOO_MAP_HYB);
          break;
        default:
          map.setMapType(YAHOO_MAP_REG);
      }
      break;
    case 'google':
    case 'openstreetmap':
      switch(type) {
        case Mapstraction.ROAD:
          map.setMapType(G_NORMAL_MAP);
          break;
        case Mapstraction.SATELLITE:
          map.setMapType(G_SATELLITE_MAP);
          break;
        case Mapstraction.HYBRID:
          map.setMapType(G_HYBRID_MAP);
          break;
        default:
          map.setMapType(G_NORMAL_MAP);
      }
      break;
    case 'microsoft':
      // TODO: oblique?
      switch(type) {
        case Mapstraction.ROAD:
          map.SetMapStyle(Msn.VE.MapStyle.Road);
          break;
        case Mapstraction.SATELLITE:
          map.SetMapStyle(Msn.VE.MapStyle.Aerial);
          break;
        case Mapstraction.HYBRID:
          map.SetMapStyle(Msn.VE.MapStyle.Hybrid);
          break;
        default:
          map.SetMapStyle(Msn.VE.MapStyle.Road);
      }
      break;
		case 'multimap':
			maptypes = map.getAvailableMapTypes();
			maptype = -1;
			for (var i = 0; i < maptypes.length; i++) {
				switch (maptypes[i]) {
					case MM_WORLD_MAP:
						if (type == Mapstraction.ROAD) {
							maptype = maptypes[i];
						}
						default_type = maptypes[i];
						break;
					case MM_WORLD_AERIAL:
						if (type == Mapstraction.SATELLITE) {
							maptype = maptypes[i];
						}
						break;
					case MM_WORLD_HYBRID:
						if (type == Mapstraction.HYBRID) {
							maptype = maptypes[i];
						}
						break;
				}
      }
			if (maptype == -1) { maptype = default_type; }
			map.setMapType(maptype);
			break;
		case 'mapquest':
			switch (type) {
				case Mapstraction.ROAD:
					myMap.setMapType("map");
					break;
				case Mapstraction.SATELLITE:
					myMap.setMapType("sat");
					break;
				case Mapstraction.HYBRID:
					myMap.setMapType("hyb");
					break;
			}
			break;
    default:
      alert(this.api + ' not supported by Mapstraction.setMapType');
  }
}

/**
 * getMapType gets the imagery type for the map.
 * The type can be one of:
 * Mapstraction.ROAD
 * Mapstraction.SATELLITE
 * Mapstraction.HYBRID
 */
Mapstraction.prototype.getMapType = function() {
  var map = this.maps[this.api];

  var type;
  switch (this.api) {
    case 'yahoo':
      type = map.getCurrentMapType();
      switch(type) {
        case YAHOO_MAP_REG:
          return Mapstraction.ROAD;
          break;
        case YAHOO_MAP_SAT:
          return Mapstraction.SATELLITE;
          break;
        case YAHOO_MAP_HYB:
          return Mapstraction.HYBRID;
          break;
        default:
          return null;
      }
      break;
    case 'google':
    case 'openstreetmap':
      type = map.getCurrentMapType();
      switch(type) {
        case G_NORMAL_MAP:
          return Mapstraction.ROAD;
          break;
        case G_SATELLITE_MAP:
          return Mapstraction.SATELLITE;
          break;
        case G_HYBRID_MAP:
          return Mapstraction.HYBRID;
          break;
        default:
          return null;
      }
      break;
    case 'microsoft':
      // TODO: oblique?
      type = map.GetMapStyle();
      switch(type) {
        case Msn.VE.MapStyle.Road:
          return Mapstraction.ROAD;
          break;
        case Msn.VE.MapStyle.Aerial:
          return Mapstraction.SATELLITE;
          break;
        case Msn.VE.MapStyle.Hybrid:
          return Mapstraction.HYBRID;
          break;
        default:
          return null;
      }
      break;
		case 'multimap':
			maptypes = map.getAvailableMapTypes();
			type = map.getMapType();
			switch(type) {
        case MM_WORLD_MAP:
          return Mapstraction.ROAD;
          break;
        case MM_WORLD_AERIAL:
          return Mapstraction.SATELLITE;
          break;
        case MM_WORLD_HYBRID:
          return Mapstraction.HYBRID;
          break;
        default:
          return null;
			}
			break;
    default:
      alert(this.api + ' not supported by Mapstraction.getMapType');
  } 
}

/**
 * getBounds gets the BoundingBox of the map
 * @returns the bounding box for the current map state
 * @type BoundingBox
 */
Mapstraction.prototype.getBounds = function () {
  var map = this.maps[this.api];

  switch (this.api) {
    case 'google':
    case 'openstreetmap':
      var gbox = map.getBounds();
      var sw = gbox.getSouthWest();
      var ne = gbox.getNorthEast();
      return new BoundingBox(sw.lat(), sw.lng(), ne.lat(), ne.lng());
      break;
    case 'yahoo':
      var ybox = map.getBoundsLatLon();
      return new BoundingBox(ybox.LatMin, ybox.LonMin, ybox.LatMax, ybox.LonMax);
      break;
    case 'microsoft':
      var mbox = map.GetMapView();
      var nw = mbox.TopLeftLatLong;
      var se = mbox.BottomRightLatLong;
      return new BoundingBox(se.Latitude,nw.Longitude,nw.Latitude,se.Longitude);
      break;
		case 'multimap':
			var mmbox = map.getMapBounds();
			var sw = mmbox.getSouthWest();
      var ne = mmbox.getNorthEast();
			return new BoundingBox(sw.lat, sw.lon, ne.lat, ne.lon);
			break;
    default:
      alert(this.api + ' not supported by Mapstraction.getBounds');
			
  }
}

/**
 * setBounds sets the map to the appropriate location and zoom for a given BoundingBox
 * @param {BoundingBox} the bounding box you want the map to show
 */
Mapstraction.prototype.setBounds = function(bounds){
  var map = this.maps[this.api];

  var sw = bounds.getSouthWest();
  var ne = bounds.getNorthEast();
  switch (this.api) {
    case 'google':
    case 'openstreetmap':
      var gbounds = new GLatLngBounds(new GLatLng(sw.lat,sw.lon),new GLatLng(ne.lat,ne.lon));
      map.setCenter(gbounds.getCenter(), map.getBoundsZoomLevel(gbounds));
      break;

    case 'yahoo':
      if(sw.lon > ne.lon)
        sw.lon -= 360;
      var center = new YGeoPoint((sw.lat + ne.lat)/2,
          (ne.lon + sw.lon)/2);

      var container = map.getContainerSize();
      for(var zoom = 1 ; zoom <= 17 ; zoom++){
        var sw_pix = convertLatLonXY_Yahoo(sw,zoom);
        var ne_pix = convertLatLonXY_Yahoo(ne,zoom);
        if(sw_pix.x > ne_pix.x)
          sw_pix.x -= (1 << (26 - zoom)); //earth circumference in pixel
        if(Math.abs(ne_pix.x - sw_pix.x)<=container.width
            && Math.abs(ne_pix.y - sw_pix.y) <= container.height){
          map.drawZoomAndCenter(center,zoom); //Call drawZoomAndCenter here: OK if called multiple times anyway
          break;
        }
      }
      break;
    case 'microsoft':
      map.SetMapView([new VELatLong(sw.lat,sw.lon),new VELatLong(ne.lat,ne.lon)]);
      break;
		case 'multimap':
			var mmlocation = map.getBoundsZoomFactor( sw.toMultiMap(), ne.toMultiMap() );
			var center = new LatLonPoint(mmlocation.coords.lat, mmlocation.coords.lon);
			this.setCenterAndZoom(center, mmlocation.zoom_factor);
			break;
    default:
      alert(this.api + ' not supported by Mapstraction.setBounds');			
  }
}

/**
 * addImageOverlay layers an georeferenced image over the map
 * @param {id} unique DOM identifier
 * @param {src} url of image
 * @param {opacity} opacity 0-100
 * @param {west} west boundary
 * @param {south} south boundary 
 * @param {east} east boundary
 * @param {north} north boundary
 */
Mapstraction.prototype.addImageOverlay = function(id, src,opacity, west, south, east, north) {
  var map = this.maps[this.api];

  var b = document.createElement("img");
  b.style.display = 'block';
  b.setAttribute('id',id);
  b.setAttribute('src',src);
  b.style.position = 'absolute';
  b.style.zIndex = 1;
  b.setAttribute('west',west);
  b.setAttribute('south',south);
  b.setAttribute('east',east);
  b.setAttribute('north',north);

  switch (this.api) {
    case 'google':
    case 'openstreetmap':
      map.getPane(G_MAP_MAP_PANE).appendChild(b);
      this.setImageOpacity(id, opacity);
      this.setImagePosition(id);
      GEvent.bind(map, "zoomend", this, function(){this.setImagePosition(id)});
      GEvent.bind(map, "moveend", this, function(){this.setImagePosition(id)});
      break;

		case 'multimap':
			map.getContainer().appendChild(b);
			this.setImageOpacity(id, opacity);
			this.setImagePosition(id);
			me = this;
			map.addEventHandler( 'changeZoom', function(eventType, eventTarget, arg1, arg2, arg3) {
				me.setImagePosition(id);
			});
			map.addEventHandler( 'drag', function(eventType, eventTarget, arg1, arg2, arg3) {
				me.setImagePosition(id);
			});
			map.addEventHandler( 'endPan', function(eventType, eventTarget, arg1, arg2, arg3) {
				me.setImagePosition(id);
			});
			break;

    default:
      b.style.display = 'none';
      alert(this.api + "not supported by Mapstraction.addImageOverlay not supported");
      break;
  }
}	 

Mapstraction.prototype.setImageOpacity = function(id, opacity) {
  if(opacity<0){opacity=0;}  if(opacity>=100){opacity=100;}
  var c=opacity/100;
  var d=document.getElementById(id);
  if(typeof(d.style.filter)=='string'){d.style.filter='alpha(opacity:'+opacity+')';}
  if(typeof(d.style.KHTMLOpacity)=='string'){d.style.KHTMLOpacity=c;}
  if(typeof(d.style.MozOpacity)=='string'){d.style.MozOpacity=c;}
  if(typeof(d.style.opacity)=='string'){d.style.opacity=c;} 
}

Mapstraction.prototype.setImagePosition = function(id) {
	var map = this.maps[this.api];
	var x = document.getElementById(id);
	var d; var e;

	switch (this.api) {
    case 'google':
    case 'openstreetmap':
			d = map.fromLatLngToDivPixel(new GLatLng(x.getAttribute('north'), x.getAttribute('west')));
			e = map.fromLatLngToDivPixel(new GLatLng(x.getAttribute('south'), x.getAttribute('east')));
			break;
		case 'multimap':
			d = map.geoPosToContainerPixels(new MMLatLon(x.getAttribute('north'), x.getAttribute('west')));
			e = map.geoPosToContainerPixels(new MMLatLon(x.getAttribute('south'), x.getAttribute('east')));
			break;
	}

	x.style.top=d.y+'px';
 	x.style.left=d.x+'px';
	x.style.width=e.x-d.x+'px';
	x.style.height=e.y-d.y+'px'; 
}

/**
 * addGeoRSSOverlay adds a GeoRSS overlay to the map
 * @param{georssURL} GeoRSS feed URL
 */
Mapstraction.prototype.addGeoRSSOverlay = function(georssURL) {
	var map = this.maps[this.api];
	
	switch (this.api) {
		case 'yahoo':
			map.addOverlay(new YGeoRSS(georssURL));
			break;
		// case 'openstreetmap': // OSM uses the google interface, so allow cascade
		case 'google':
			map.addOverlay(new GGeoXml(georssURL));
			break;
		case 'microsoft':
		    var veLayerSpec = new VELayerSpecification();
            veLayerSpec.Type = VELayerType.GeoRSS;
            veLayerSpec.ID = 1;
            veLayerSpec.LayerSource = georssURL;
            veLayerSpec.Method = 'get';
            // veLayerSpec.FnCallback = onFeedLoad;
            map.AddLayer(veLayerSpec);
			break;
		// case 'openlayers':
		// 	map.addLayer(new OpenLayers.Layer.GeoRSS("GeoRSS Layer", georssURL));
			// break;
		case 'multimap':
		default:
			alert(this.api + ' not supported by Mapstraction.addGeoRSSOverlay');
	}

}

/**
 * addFilter adds a marker filter
 * @param {field} name of attribute to filter on
 * @param {operator} presently only "ge" or "le"
 * @param {value} the value to compare against
 */
Mapstraction.prototype.addFilter = function(field, operator, value) {
	if (! this.filters) {
		this.filters = [];
	}
	this.filters.push( [field, operator, value] );
}

/**
 * doFilter executes all filters added since last call
 */
Mapstraction.prototype.doFilter = function() {
	var map = this.maps[this.api];

	if (this.filters) {

		switch (this.api) {
			case 'multimap':
				var mmfilters = [];
				for (var f=0; f<this.filters.length; f++) {
					mmfilters.push( new MMSearchFilter( this.filters[f][0], this.filters[f][1], this.filters[f][2] ));
				}
				map.setMarkerFilters( mmfilters );	
				map.redrawMap();			
			break;
			default:
				for (var m=0; m<this.markers.length; m++) {
					this.markers[m].vis = true;
					for (var f=0; f<this.filters.length; f++) {
						switch (this.filters[f][1]) {
							case 'ge':
								if (this.markers[m].getAttribute( this.filters[f][0] ) < this.filters[f][2]) {
									this.markers[m].vis = false;
								}
								break;
							case 'le':
								if (this.markers[m].getAttribute( this.filters[f][0] ) > this.filters[f][2]) {
									this.markers[m].vis = false;
								}
								break;
						}
					}
					if (this.markers[m].vis) {
						this.markers[m].show();
					} else {
						this.markers[m].hide();
					}
				}
			break;
		}

	}
	this.filters = [];
}

/**
 * getAttributeExtremes returns the minimum/maximum of "field" from all markers
 * @param {field} name of "field" to query
 * @returns {array} of minimum/maximum
 */
Mapstraction.prototype.getAttributeExtremes = function(field) {
	var min;
	var max;
	for (var m=0; m<this.markers.length; m++) {
		if (! min || min > this.markers[m].getAttribute(field)) {
			min = this.markers[m].getAttribute(field);
		}
		if (! max || max < this.markers[m].getAttribute(field)) {
			max = this.markers[m].getAttribute(field);
		}
	}

	return [min, max];
}

/**
 * getMap returns the native map object that mapstraction is talking to
 * @returns the native map object mapstraction is using
 */
Mapstraction.prototype.getMap = function() {
  // FIXME in an ideal world this shouldn't exist right?
  return this.maps[this.api];
}


//////////////////////////////
//
//   LatLonPoint
//
/////////////////////////////

/**
 * LatLonPoint is a point containing a latitude and longitude with helper methods
 * @param {double} lat is the latitude
 * @param {double} lon is the longitude
 * @returns a new LatLonPoint
 * @type LatLonPoint
 */
function LatLonPoint(lat,lon) {
  // TODO error if undefined?
  //  if (lat == undefined) alert('undefined lat');
  //  if (lon == undefined) alert('undefined lon');
  this.lat = lat;
  this.lon = lon;
  this.lng = lon; // lets be lon/lng agnostic
}

/**
 * toYahoo returns a Y! maps point
 * @returns a YGeoPoint
 */
LatLonPoint.prototype.toYahoo = function() {
  return new YGeoPoint(this.lat,this.lon);
}
/**
 * toGoogle returns a Google maps point
 * @returns a GLatLng
 */
LatLonPoint.prototype.toGoogle = function() {
  return new GLatLng(this.lat,this.lon);
}
/**
 * toMicrosoft returns a VE maps point
 * @returns a VELatLong
 */
LatLonPoint.prototype.toMicrosoft = function() {
  return new VELatLong(this.lat,this.lon);
}
/**
 * toMultiMap returns a MultiMap point
 * @returns a MMLatLon
 */
LatLonPoint.prototype.toMultiMap = function() {
	return new MMLatLon(this.lat, this.lon);
}

/**
 * toMapQuest returns a MapQuest point
 * @returns a MQLatLng
 */
LatLonPoint.prototype.toMapQuest = function() {
	return new MQLatLng(this.lat, this.lon);
}


/**
 * toString returns a string represntation of a point
 * @returns a string like '51.23, -0.123'
 * @type String
 */
LatLonPoint.prototype.toString = function() {
  return this.lat + ', ' + this.lon;
}
/**
 * distance returns the distance in kilometers between two points
 * @param {LatLonPoint} otherPoint The other point to measure the distance from to this one
 * @returns the distance between the points in kilometers
 * @type double
 */
LatLonPoint.prototype.distance = function(otherPoint) {
  var d,dr;
  with (Math) {
    dr = 0.017453292519943295; // 2.0 * PI / 360.0; or, radians per degree
    d = cos(otherPoint.lon*dr - this.lon*dr) * cos(otherPoint.lat*dr - this.lat*dr);
    return acos(d)*6378.137; // equatorial radius
  }
  return -1; 
}
/**
 * equals tests if this point is the same as some other one
 * @param {LatLonPoint} otherPoint The other point to test with
 * @returns true or false
 * @type boolean
 */
LatLonPoint.prototype.equals = function(otherPoint) {
  return this.lat == otherPoint.lat && this.lon == otherPoint.lon;
}

//////////////////////////
//
//  BoundingBox
//
//////////////////////////

/**
 * BoundingBox creates a new bounding box object
 * @param {double} swlat the latitude of the south-west point
 * @param {double} swlon the longitude of the south-west point
 * @param {double} nelat the latitude of the north-east point
 * @param {double} nelon the longitude of the north-east point
 * @returns a new BoundingBox
 * @type BoundinbBox
 * @constructor
 */
function BoundingBox(swlat, swlon, nelat, nelon) {
  //FIXME throw error if box bigger than world
  //alert('new bbox ' + swlat + ',' +  swlon + ',' +  nelat + ',' + nelon);
  this.sw = new LatLonPoint(swlat, swlon);
  this.ne = new LatLonPoint(nelat, nelon);
}

/**
 * getSouthWest returns a LatLonPoint of the south-west point of the bounding box
 * @returns the south-west point of the bounding box
 * @type LatLonPoint
 */
BoundingBox.prototype.getSouthWest = function() {
  return this.sw;
}

/**
 * getNorthEast returns a LatLonPoint of the north-east point of the bounding box
 * @returns the north-east point of the bounding box
 * @type LatLonPoint
 */
BoundingBox.prototype.getNorthEast = function() {
  return this.ne;
}

/**
 * isEmpty finds if this bounding box has zero area
 * @returns whether the north-east and south-west points of the bounding box are the same point
 * @type boolean
 */
BoundingBox.prototype.isEmpty = function() {
  return this.ne == this.sw; // is this right? FIXME
}

/**
 * contains finds whether a given point is within a bounding box
 * @param {LatLonPoint} point the point to test with
 * @returns whether point is within this bounding box
 * @type boolean
 */
BoundingBox.prototype.contains = function(point){
  return point.lat >= this.sw.lat && point.lat <= this.ne.lat && point.lon>= this.sw.lon && point.lon <= this.ne.lon;
}

/**
 * toSpan returns a LatLonPoint with the lat and lon as the height and width of the bounding box
 * @returns a LatLonPoint containing the height and width of this bounding box
 * @type LatLonPoint
 */
BoundingBox.prototype.toSpan = function() {
  return new LatLonPoint( Math.abs(this.sw.lat - this.ne.lat), Math.abs(this.sw.lon - this.ne.lon) );
}

//////////////////////////////
//
//  Marker
//
///////////////////////////////

/**
 * Marker create's a new marker pin
 * @param {LatLonPoint} point the point on the map where the marker should go
 * @constructor
 */
function Marker(point) {
  this.location = point;
  this.onmap = false;
  this.proprietary_marker = false;
	this.attributes = new Array;
  this.pinID = "mspin-"+new Date().getTime()+'-'+(Math.floor(Math.random()*Math.pow(2,16)));
}

Marker.prototype.setChild = function(some_proprietary_marker) {
  this.proprietary_marker = some_proprietary_marker;
  this.onmap = true
}

Marker.prototype.setLabel = function(labelText) {
  this.labelText = labelText;
}

/**
 * setInfoBubble sets the html/text content for a bubble popup for a marker
 * @param {String} infoBubble the html/text you want displayed
 */
Marker.prototype.setInfoBubble = function(infoBubble) {
  this.infoBubble = infoBubble;
}

/**
 * setInfoDiv sets the text and the id of the div element where to the information
 *  useful for putting information in a div outside of the map
 * @param {String} infoDiv the html/text you want displayed
 * @param {String} div the element id to use for displaying the text/html
 */
Marker.prototype.setInfoDiv = function(infoDiv,div){
  this.infoDiv = infoDiv;
  this.div = div;
}

/**
 * setIcon sets the icon for a marker
 * @param {String} iconUrl The URL of the image you want to be the icon
 */
Marker.prototype.setIcon = function(iconUrl){
  this.iconUrl = iconUrl;
}

/**
 * toYahoo returns a Yahoo Maps compatible marker pin
 * @returns a Yahoo Maps compatible marker
 */
Marker.prototype.toYahoo = function() {
  var ymarker;
  if(this.iconUrl){
    ymarker = new YMarker(this.location.toYahoo (),new YImage(this.iconUrl
          ));
  }else{
    ymarker = new YMarker(this.location.toYahoo());
  }
  if(this.labelText) {
    ymarker.addLabel(this.labelText);

  }

  if(this.infoBubble) {
    var theInfo = this.infoBubble;
    YEvent.Capture(ymarker, EventsList.MouseClick, function() {
        ymarker.openSmartWindow(theInfo); });
  }

  if(this.infoDiv) {
    var theInfo = this.infoDiv;
    var div = this.div;
    YEvent.Capture(ymarker, EventsList.MouseClick, function() {
        document.getElementById(div).innerHTML = theInfo;});

  }

  return ymarker;
}

/**
 * toGoogle returns a Google Maps compatible marker pin
 * @returns Google Maps compatible marker
 */
Marker.prototype.toGoogle = function() {
  var options = new Object();
  if(this.labelText) {
    options.title =  this.labelText;
  }
  if(this.iconUrl){
    options.icon = new GIcon(G_DEFAULT_ICON,this.iconUrl);
  }
  var gmarker = new GMarker( this.location.toGoogle(),options);


  if(this.infoBubble) {
    var theInfo = this.infoBubble;
    GEvent.addListener(gmarker, "click", function() {
        gmarker.openInfoWindowHtml(theInfo);
        });
  }

  if(this.infoDiv){
    var theInfo = this.infoDiv;
    var div = this.div;
    GEvent.addListener(gmarker, "click", function() {
        document.getElementById(div).innerHTML = theInfo;
        });
  }

  return gmarker;
}

/**
 * toMicrosoft returns a MSFT VE compatible marker pin
 * @returns MSFT VE compatible marker
 */
Marker.prototype.toMicrosoft = function() {
  var pin = new VEPushpin(this.pinID,this.location.toMicrosoft(),
      this.iconUrl,this.labelText,this.infoBubble);
  return pin;
}


/**
 * toMultiMap returns a MultiMap compatible marker pin
 * @returns MultiMap compatible marker
 */
Marker.prototype.toMultiMap = function() {
	if (this.iconUrl) {
		var icon = new MMIcon(this.iconUrl);
		icon.iconSize = new MMDimensions(32, 32); //how to get this?
		
		var mmmarker = new MMMarkerOverlay( this.location.toMultiMap(), {'icon' : icon} );
	} else {
		var mmmarker = new MMMarkerOverlay( this.location.toMultiMap());
	}
	if(this.labelText){
	}
	if(this.infoBubble) {
		mmmarker.setInfoBoxContent(this.infoBubble);
	}
	if(this.infoDiv) {
	}

	for (var key in this.attributes) {
		mmmarker.setAttribute(key, this.attributes[ key ]);
	}

	return mmmarker;
}

/**
 * toMapQuest returns a MapQuest compatible marker pin
 * @returns MapQuest compatible marker
 */
Marker.prototype.toMapQuest = function() {

  var mqmarker = new MQPoi( this.location.toMapQuest() );

  if(this.iconUrl){
    var mqicon = new MQMapIcon();
		mqicon.setImage(this.iconUrl,32,32,true,false);
		// TODO: Finish MapQuest icon params - icon file location, width, height, recalc infowindow offset, is it a PNG image?
		mqmarker.setIcon(mqicon);
		// mqmarker.setLabel('Hola!');
  }

  if(this.labelText) { mqmarker.setInfoTitleHTML( this.labelText ); }

  if(this.infoBubble) { mqmarker.setInfoContentHTML( this.infoBubble ); }

  if(this.infoDiv){
    var theInfo = this.infoDiv;
    var div = this.div;
    MQEventManager.addListener(mqmarker, "click", function() {
        document.getElementById(div).innerHTML = theInfo;
        });
  }

  return mqmarker;
}

/**
 * setAttribute: set an arbitrary key/value pair on a marker
 * @arg(String) key
 * @arg value
 */
Marker.prototype.setAttribute = function(key,value) {
	this.attributes[key] = value;
}

/**
 * getAttribute: gets the value of "key"
 * @arg(String) key
 * @returns value
 */
Marker.prototype.getAttribute = function(key) {
	return this.attributes[key];
}



/**
 * openBubble opens the infoBubble
 */
Marker.prototype.openBubble = function() {
  if( this.api) { 
    switch (this.api) {
      case 'yahoo':
        var ypin = this.proprietary_marker;
        ypin.openSmartWindow(this.infoBubble);
        break;
      case 'google':
      case 'openstreetmap':
        var gpin = this.proprietary_marker;
        gpin.openInfoWindowHtml(this.infoBubble);
        break;
      case 'microsoft':
        var pin = this.proprietary_marker;
        // bloody microsoft
        var el = $(this.pinID + "_" + this.maps[this.api].GUID).onmouseover;
        setTimeout(el, 1000); // wait a second in case the map is booting as it cancels the event
				break;
			case 'multimap':
				this.proprietary_marker.openInfoBox();
				break;
			case 'mapquest':
				// MapQuest hack to work around bug when opening marker
				this.proprietary_marker.setRolloverEnabled(false);
				this.proprietary_marker.showInfoWindow();
				this.proprietary_marker.setRolloverEnabled(true);			
				break;
    }
  } else {
    alert('You need to add the marker before opening it');
  }
}

/**
 * hide the marker
 */
Marker.prototype.hide = function() {
	if (this.api) {
		switch (this.api) {
			case 'google':
			case 'openstreetmap':
				this.proprietary_marker.hide();
				break;
			case 'yahoo':
				this.proprietary_marker.hide();
				break;
			case 'multimap':
				this.proprietary_marker.setVisibility(false);
				break;
			case 'mapquest':
				this.proprietary_marker.setVisible(false);
				break;				
			default:
				alert(this.api + "not supported by Marker.hide");
		}
	}
}

/**
 * show the marker
 */
Marker.prototype.show = function() {
	if (this.api) {
		switch (this.api) {
			case 'google':
			case 'openstreetmap':
				this.proprietary_marker.show();
				break;
			case 'yahoo':
				this.proprietary_marker.unhide();
				break;
			case 'multimap':
				this.proprietary_marker.setVisibility(true);
				break;
			case 'mapquest':
				this.proprietary_marker.setVisible(true);
				break;	
			default:
				alert(this.api + "not supported by Marker.show");
		}
	}
}

///////////////
// Polyline ///
///////////////


function Polyline(points) {
  this.points = points;
  this.onmap = false;
  this.proprietary_polyline = false;
  this.pllID = "mspll-"+new Date().getTime()+'-'+(Math.floor(Math.random()*Math.pow(2,16)));
}

Polyline.prototype.setChild = function(some_proprietary_polyline) {
  this.proprietary_polyline = some_proprietary_polyline;
  this.onmap = true;
}

//in the form: #RRGGBB
Polyline.prototype.setColor = function(color){
  this.color = color;
}

//An integer
Polyline.prototype.setWidth = function(width){
  this.width = width;
}

//A float between 0.0 and 1.0
Polyline.prototype.setOpacity = function(opacity){
  this.opacity = opacity;
}

Polyline.prototype.toYahoo = function() {
  var ypolyline;
  var ypoints = [];
  for (var i = 0, length = this.points.length ; i< length; i++){
    ypoints.push(this.points[i].toYahoo());
  }
  ypolyline = new YPolyline(ypoints,this.color,this.width,this.opacity);
  return ypolyline;
}

Polyline.prototype.toGoogle = function() {
  var gpolyline;
  var gpoints = [];
  for (var i = 0,  length = this.points.length ; i< length; i++){
    gpoints.push(this.points[i].toGoogle());
  }
  gpolyline = new GPolyline(gpoints,this.color,this.width,this.opacity);
  return gpolyline;
}

Polyline.prototype.toMicrosoft = function() {
  var mpolyline;
  var mpoints = [];
  for (var i = 0, length = this.points.length ; i< length; i++){
    mpoints.push(this.points[i].toMicrosoft());
  }

  var color;
  var opacity = this.opacity ||1.0;
  if(this.color){
    color = new VEColor(parseInt(this.color.substr(1,2),16),parseInt(this.color.substr(3,2),16),parseInt(this.color.substr(5,2),16), opacity);
  }else{
    color = new VEColor(0,255,0, opacity);
  }

  mpolyline = new VEPolyline(this.pllID,mpoints,color,this.width);
  return mpolyline;
}

Polyline.prototype.toMultiMap = function() {
	var mmpolyline;
	var mmpoints = [];
	 for (var i = 0, length = this.points.length ; i< length; i++){
    mmpoints.push(this.points[i].toMultiMap());
  }
	mmpolyline = new MMPolyLineOverlay(mmpoints, this.color, this.opacity, this.width, false, undefined);
	return mmpolyline;
}

Polyline.prototype.toMapQuest = function() {
	var mqpolyline = new MQLineOverlay();
	mqpolyline.setColor(this.color);
	mqpolyline.setBorderWidth(this.width);
	mqpolyline.setKey("Line");
	mqpolyline.setOpacity(this.opacity);

	var mqpoints = new MQLatLngCollection();
	for (var i = 0, length = this.points.length ; i< length; i++){
	  mqpoints.add(this.points[i].toMapQuest());
	}
	mqpolyline.setShapePoints(mqpoints);
	return mqpolyline;
}


/////////////
/// Route ///
/////////////

/**
 * Show a route from MapstractionRouter on a mapstraction map
 * Currently only supported by MapQuest
 * @params {Object} route The route object returned in the callback from MapstractionRouter
 */
Mapstraction.prototype.showRoute = function(route) { 
	var map = this.maps[this.api];
	switch (this.api) {
		case 'mapquest':
			map.addRouteHighlight(route['bounding_box'],"http://map.access.mapquest.com",route['session_id'],true);
			break;
    default:
      alert(api + ' not supported by Mapstration.showRoute');
			break;
	}
}

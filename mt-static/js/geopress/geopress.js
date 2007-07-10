// Global geo_maps array and array size
var geo_maps = new Array(); 
var num_maps = 0;
var geo_map; 

function geopress_storezoom(elem) {
	$('geopress_map_zoom').value = geo_map.getZoom();	
}
// Creates a map 
function geopress_makemap(map_id, name, lat, lon, map_format, map_type, map_controls, map_zoom) {
  num_maps = geo_maps.push(new Mapstraction("geo_map" + map_id, map_format)) - 1;
  var myPoint = new LatLonPoint(lat, lon);
  geo_maps[num_maps].addControls(map_controls);
  geo_maps[num_maps].setCenterAndZoom(myPoint, map_zoom);
  geo_maps[num_maps].setMapType(map_type);
  var marker = new Marker(myPoint);
  marker.setInfoBubble(name);
  geo_maps[num_maps].addMarker(marker);
}
function geopress_setmap() {
	geo_map.removeAllMarkers();
	var myPoint = new LatLonPoint(30,-90);
	geo_map.setCenterAndZoom(myPoint, 8);
	var marker = new Marker(myPoint);
	marker.setInfoBubble("@ Pointed");
	geo_map.addMarker(marker);
}


// addPointToMap() adds a marker at a specific point from either 
// a geocoder response or the user clicking on the map. 
// @todo handle drawing polylines
function addPointToMap(point) {
	geo_map.removeAllMarkers();
	marker = new Marker(point);
	geo_map.setCenterAndZoom(point,10);
	marker.setInfoBubble(point.toString());
	geo_map.addMarker(marker);
}
function returnObjById( id )
{
    var returnVar;
    if (document.getElementById)
        returnVar = document.getElementById(id);
    else if (document.all)
        returnVar = document.all[id];
    else if (document.layers)
        returnVar = document.layers[id];
    return returnVar;
}

 // addAddressToMap() is called when the geocoder returns an
 // answer.  It adds a marker to the map with an open info window
 // showing the nicely formatted version of the address and the country code.
function addAddressToMap(response, element) {
//   map.clearOverlays();
	if(!element)
		element = "geometry";
		
  if (!response || response.Status.code != 200) {
    alert("Sorry, we were unable to geocode that address");
  } else {
    place = response.Placemark[0];
    point = new LatLonPoint(place.Point.coordinates[1],
                        place.Point.coordinates[0]);
    addPointToMap(point);
	returnObjById(element).value = place.Point.coordinates[1] + ", " + place.Point.coordinates[0];
  }
}

 // showLocation() is called when you click on the Search button
 // in the form.  It geocodes the address entered into the form
 // and adds a marker to the map at that location.
function showLocation(addr, geometry) {
	
	if(!addr)
		addr = 'addr';
		
	// var address = //document.forms[0].addr	
	var address = returnObjById(addr).value;
	
	if(address) {
		// If the 'address' is just points, map them
   		if(matches = address.match(/\[(.+),[ ]?(.+)\]/)) {
			setMapPoint(new LatLonPoint(matches[1], matches[2]));
		} else {
			geocoder.getLocations(address, function(response) { addAddressToMap(response, geometry)});
		}
	}
}

function geocode(element, geometry) {
	if(element == null)
		element = 'locname';
		
//	document.forms[0].locname.value = "";
	// returnObjById(element).value = "";

	showLocation(element, geometry);   
}
// findLocation() is used to enter the sample addresses into the form.
function findLocation(address) {
	//document.forms[0].addr	
	returnObjById('addr').value = address;
	showLocation();
}
var gPoint;
// setMapPoint() handles a user clicking on a map
function setMapPoint(point) {
	//document.forms[0].addr	
    returnObjById('addr').value = "[" + point + "]";
	geo_map.removeAllMarkers();
	addPointToMap(point);
}

function geopress_resetMap() {
	geo_map.setCenterAndZoom(new LatLonPoint(0,0),1);
}

// used to register onload events to the body 
function geopress_addEvent(obj, evType, fn){ 
 if (obj.addEventListener){ 
   obj.addEventListener(evType, fn, false); 
   return true; 
 } else if (obj.attachEvent){ 
   var r = obj.attachEvent("on"+evType, fn); 
   return r; 
 } else { 
   return false; 
 } 
}

// Handles loading a saved address
function geopress_loadsaved(oSel, addr_element, locname_element) { 

   if ( ! addr_element )
      addr_element = 'addr';
      
   if ( ! locname_element )
      locname_element = 'locname';

   var addr = oSel.options[oSel.selectedIndex].value;
   var name = oSel.options[oSel.selectedIndex].text;
   
   addrobj = returnObjById(addr_element);
   locnameobj = returnObjById(locname_element);
   addrobj.value = addr;
   locnameobj.value = name;

   oSel.selectedIndex = 0;
}
function checkEnter(e,elem){ //e is event object passed from function invocation
	var characterCode;// literal character code will be stored in this variable

	if(e && e.which){ //if which property of event object is supported (NN4)
		e = e
		characterCode = e.which //character code is contained in NN4s which property
	}
	else{
		e = event
		characterCode = e.keyCode //character code is contained in IEs keyCode property
	}

	if(characterCode == 13){ //if generated character code is equal to ascii 13 (if enter key)
		geocode();				
		return false
	}
	else{
		return true
	}
}

//
// Map Configuration Functions
//
// Handles changing the map controls
function geopress_change_controls(oSel) { 

	var map_controls_pan = document.getElementById("map_controls_pan").checked;
	var map_controls_zoom = document.getElementById("map_controls_zoom").value;
	var map_controls_overview = document.getElementById("map_controls_overview").checked;
	var map_controls_map_type = document.getElementById("map_controls_map_type").checked;
	var map_controls_scale = document.getElementById("map_controls_scale").checked;
	geo_map.addControls({
		pan:      map_controls_pan,
		zoom:     map_controls_zoom,
		overview: map_controls_overview,
		scale:    map_controls_scale,
		map_type: map_controls_map_type
	});
}
// Handles changing the map format
function geopress_change_map_format() { 

	var map_format = document.getElementById("default_map_format").value;
	geo_map.swap(map_format);
}
// Handles changing the map format
function geopress_change_map_size() { 
	var map_width = document.getElementById("map_width").value;
	var map_height = document.getElementById("map_height").value;
	geo_map.resizeTo(map_width, map_height);
}
// Handles changing the map view type (street, satellite, hybrid)
function geopress_change_view() { 

	var type_string = document.getElementById("default_map_type").value;
	var type;
	switch(type_string) {
		case "satellite":
			type = Mapstraction.SATELLITE;
			break;
		case "road":
			type = Mapstraction.ROAD;
			break;
		case "hybrid":
			type = Mapstraction.HYBRID;
			break;
		default :
			type = Mapstraction.HYBRID;
			break;
	}
	geo_map.setMapType(type);

}
// Handles changing the map default zoom level
function geopress_change_zoom() { 

	var zoom_level = document.getElementById("default_zoom_level").value;
	geo_map.setZoom(zoom_level);

}


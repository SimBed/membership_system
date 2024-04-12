var myCenter=new google.maps.LatLng(19.112355,72.827235);
var mySpaceTag=new google.maps.LatLng(19.110677,72.825229);

function init_map()
{
var myOptions = {
  center:myCenter,
  zoom:16,
  mapTypeId: google.maps.MapTypeId.ROADMAP
};

let map = new google.maps.Map(document.getElementById('gmap_canvas'), myOptions);

let marker = new google.maps.Marker({
  map: map,
  position: mySpaceTag,
});

let infowindow = new google.maps.InfoWindow({
  content:"<b>The Space</b><br><br>AB Nair Rd<br>Juhu, Mumbai <br> Maharashtra 400049<br><br>(directly opposite Chin Chin Chu)<br>(Please during 2024 use temporary side entrance on Silver Beach Estate)"
});

google.maps.event.addListener(marker, 'click', function(){infowindow.open(map,marker);});infowindow.open(map,marker);}

google.maps.event.addDomListener(window, 'load', init_map);

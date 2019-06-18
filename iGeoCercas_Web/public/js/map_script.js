/*
 * Global Variables
 */ 
var marker = null;
var map;
var arrayPolygon = [];
var arrayCircle = [];
var centerCoord = {
  lat: 37.331717, 
  lng: -122.031060
};
var drawingManager;
/* SOCKET CLIENT */
var socket = io('http://localhost:3000');//poner la ip del servidor 192.168.x.y:3000

//para verificar que si se conecte
console.log("Web client connection succesful!");

var _txtMensaje = document.getElementById("txtMessage");

// Enviar al servidor los datos a procesar:
var SEND = function(){
  var obj = {
    "title":"Connection Succesful",
    "message":"Connected to socket server!"
  };
  console.log("Sending to server: " + JSON.stringify(obj));
  socket.emit('messageToServer',obj);//It sends the info to the server. The server will receive the info and send the notification to the devices with that specific ID.
};

socket.on('coordToWeb', (data) => { 
  var objJson = JSON.parse(data);
  var latlng = new google.maps.LatLng(objJson.lat, objJson.lng);
  if(marker === null){
    marker = new google.maps.Marker({
      position: latlng,
      map: map,
      title: socket.id
    });
  }
  else{
    marker.setPosition(latlng);
  }
  isCoordinateInsidePoligon(objJson.lat, objJson.lng);
});

/*
-  Map: 
*/

function initMap() {
  map = new google.maps.Map(document.getElementById('map'), {
    center: centerCoord,
    zoom: 16
  });
  drawingManager = new google.maps.drawing.DrawingManager({
    drawingMode: google.maps.drawing.OverlayType.MARKER,
    drawingControl: true,
    drawingControlOptions: {
      position: google.maps.ControlPosition.TOP_CENTER,
      drawingModes: ['marker', 'circle', 'polygon']
    },
    markerOptions: {
      icon: "img/marker-icon.png"
      //icon: 'https://prospectareachamber.org/wp-content/uploads/2017/12/map-marker-icon-e1512334260964.png'
    },
    circleOptions: {
      fillColor: '#ffff00',
      fillOpacity: 0.2,
      strokeWeight: 4,
      clickable: true,
      editable: true,
      zIndex: 1
    }
  });
  drawingManager.setMap(map);

  google.maps.event.addListener(drawingManager, 'circlecomplete', function(circle) {
    arrayCircle.push(circle); 
  });
  google.maps.event.addListener(drawingManager, 'markercomplete', function(marker) {
    //the following code is created to simulate the coordinates sended by the ios device:
    var lat = marker.getPosition().lat();
    var lng = marker.getPosition().lng();
    isCoordinateInsidePoligon(lat, lng);
  });

  google.maps.event.addListener(drawingManager, 'polygoncomplete', function (polygon) {
    arrayPolygon.push(polygon); 
  });

  google.maps.event.addListener(drawingManager, 'overlaycomplete', function(event) {
    /*if (event.type == 'circle') {
      var radius = event.overlay.getRadius();
    }*/
  });
}


// Functions:
function isCoordinateInsidePoligon(latitude, longitude){
  var coordinate = new google.maps.LatLng(latitude, longitude);                                                                                                                                                                                                       

  var isInside = false;

  //iterate through all of the circles saved:
  arrayCircle.forEach(currentCircle => {
    var radius = currentCircle.getRadius();
    var center = currentCircle.getCenter();
    isInside = google.maps.geometry.spherical.computeDistanceBetween(coordinate, center) <= radius;
  });
  //iterate through all of the poligons saved:
  arrayPolygon.forEach(currentPolygon => {
    isInside = google.maps.geometry.poly.containsLocation(coordinate, currentPolygon) ? true : false;
  });
  if(isInside){
    //send the socket message notificaction to the specific client (ios app)
    this.SEND();
  }
}
function cleanMap(){
  //drawingManager.setMap(null);
}

/*
-  UI: 
*/
function showPanel() {
  var displayStatus = document.getElementById('sidebar').style.display;
  if (displayStatus === "none" || displayStatus === "") {
    document.getElementById('sidebar').style.display = "inline-block";
  }
  else {
    document.getElementById('sidebar').style.display = "none";
  }
}


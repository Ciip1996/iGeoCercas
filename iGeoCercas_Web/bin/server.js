//Crear dos instancias y exportarlas
var io = require('socket.io')(); //instancias librerias de io en esta variable con todos los metodos y funciones

io.sockets.on('connection', function(socket){ 
    console.log("connection succesful on socket io with id: " + socket.id);
    
    /*obj = {
      "title":"Connected succesfully",
      "message":"with Web Client!"
    };*/
    io.sockets.emit('notification',JSON.stringify("ok"));
    
    socket.on('coordToServer', (data) => { 
      //console.log('Received the following message from ios platform:');
      console.log(data);
      //console.log('Emitting to the web manager platform!');
      io.sockets.emit('coordToWeb',data);
    });
    socket.on('messageToServer', (data) => { 
      console.log('Received message from Web Manager!');
      console.log('Sending notificaton to ios clients!');
      console.log(JSON.stringify(data));
      io.sockets.emit('notification',JSON.stringify(data));
    });
    socket.on('disconnect', function () {
      console.log('user ' + socket.id + ' got disconnected');
    });
    
});

module.exports = io;
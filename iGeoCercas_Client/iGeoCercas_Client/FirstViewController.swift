//
//  FirstViewController.swift
//  iGeoCercas_Client
//
//  Created by Iván Pacheco on 14/06/19.
//  Copyright © 2019 Iván Pacheco. All rights reserved.
//

import UIKit
import MapKit
import Foundation
import CoreLocation
import SocketIO
import UserNotifications

class FirstViewController: UIViewController, CLLocationManagerDelegate {

    struct Coordenate: Codable {
        var message: String
        var lat: Double
        var lng: Double
    }
    
    let manager = SocketManager(socketURL: URL(string: "http://localhost:3000")!, config: [.log(true), .compress])
    var socket:SocketIOClient!
    var name: String?
    var resetAck: SocketAckEmitter?

    @IBOutlet weak var map: MKMapView!
    var locationManager: CLLocationManager!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.map.showsUserLocation = true;
        connectSocketServer()

        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    func connectSocketServer(){
        self.socket = manager.defaultSocket
        
        socket.on("notification") { data,ack  in
            /* CREATE A NOTIFICATION HERE */
            print("<    Received notification from server   > ")
            self.displayNotification()// To finish
            self.displayMessage()// To finish
        }
        /*socket.on(clientEvent: .connect) {data, ack in
            print("\n\n\t\t Sockets Connected")
        }*/
        socket.connect()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = locations.last! as CLLocation
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.map.setRegion(region, animated: true)
        
        do{
            var coord = Coordenate(message: "message here", lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            let jsonData = try JSONEncoder().encode(coord)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            print("emitting the coordenates to the server")
            self.socket.emit("coordToServer", with: [jsonString])
        } catch {
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func displayMessage(){
        let alert = UIAlertController(title: "Estas entrando en areas prohibidas", message: "Te recomendamos que salgas ahora antes de que te pase algo peligroso.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func displayNotification(){
        // 1
        let content = UNMutableNotificationContent()
        content.title = "Notification Tutorial"
        content.subtitle = "from ioscreator.com"
        content.body = " Notification triggered"
        // 2
        let imageName = "promo"
        guard let imageURL = Bundle.main.url(forResource: imageName, withExtension: "png") else {
            print("no image")
            return
        }
        let attachment = try! UNNotificationAttachment(identifier: imageName, url: imageURL, options: .none)
        content.attachments = [attachment]
        // 3
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "notification.id.01", content: content, trigger: trigger)
        // 4
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}


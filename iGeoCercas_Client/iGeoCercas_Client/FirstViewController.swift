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
    struct Response: Decodable{
        var title: String
        var message: String
    }
    struct JsonResponse: Codable{
        var title: String
        var message: String
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
        
        socket.on("notification") {data,ack in
            /* CREATE A NOTIFICATION HERE */
            print("<    Received notification from server   > ")
            guard let cur = data[0] as? String else {
                self.displayMessage(withTitle: "error", withMessage: "de parseo")
                return
            }
            let jsonData = cur.data(using: .utf8)!
            do {
                guard let response = try? JSONDecoder().decode(Response.self, from: jsonData) else {
                    print("Error: Couldn't decode data")
                    return
                }//self.displayNotification(withTitle: response.title, withMessage: response.message)
                self.displayMessage(withTitle: response.title, withMessage: response.message)
            } catch {
                print(error)
            }
                
        }
        socket.on(clientEvent: SocketClientEvent.reconnectAttempt){data, ack in
            self.displayMessage(withTitle: "Reconnect attempt", withMessage: "The app is trying to connect to the socket server.")
        }
        socket.on(clientEvent: SocketClientEvent.reconnect){data, ack in
            self.displayMessage(withTitle: "Reconnected to Server!", withMessage: "The app is now connected to the socket server.")
        }
        socket.on(clientEvent: SocketClientEvent.error){data, ack in
            guard let cur = data[0] as? String else { return }
            self.displayMessage(withTitle: "Server Error", withMessage: cur)
        }
        socket.on(clientEvent: .connect) {data, ack in
            print("\n\n\t\t Sockets Connected")
            self.displayMessage(withTitle: "Connection stablished", withMessage: "Now connected to server.")
        }
        socket.connect()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = locations.last! as CLLocation
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.map.setRegion(region, animated: true)
        
        do{
            let coord = Coordenate(message: "message here", lat: location.coordinate.latitude, lng: location.coordinate.longitude)
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
    
    func displayMessage(withTitle:String, withMessage:String){
        let alert = UIAlertController(title: withTitle, message: withMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func displayNotification(withTitle:String, withMessage:String){
        // 1
        let content = UNMutableNotificationContent()
        content.title = withTitle
        content.subtitle = "message from server"
        content.body = withMessage
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


//
//  ViewController.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 30.01.2023.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var uiView: UIView!
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    
    
    var locationManager: CLLocationManager?
    var route: GMSPolyline? //линия пути
    var routePath: GMSMutablePath? //пройденный путь/маршрут
    
    var track: Track?
    var isTracking: Bool?
    var zoom: Float = 15
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureMap()
        configureLocationManager()
        
    }
    
    private func configureUI() {
        uiView.layer.cornerRadius = 16
        let color = uiView.backgroundColor
        uiView.backgroundColor = color?.withAlphaComponent(0.9)
    }
    
    private func configureMap() {
        //guard let coordinate = locationManager?.location?.coordinate else { return }
        //print(coordinate)
        let camera = GMSCameraPosition.camera(withTarget: CLLocationCoordinate2D(latitude: 0, longitude: 0), zoom: zoom)
        mapView.camera = camera
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
    }
    
    private func configureLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.requestLocation()
        locationManager?.startUpdatingLocation()
    }
    
    private func addMarker(coordinate: CLLocationCoordinate2D, title: String? = nil, description: String? = nil) {
        let marker = GMSMarker(position: coordinate)
        marker.title = title
        marker.snippet = description
        marker.map = mapView
    }
    
    private func removeTrack() {
        track = nil
        route?.map = nil
    }
    
    private func trackInfo() {
        guard
            let track = track,
            let duration = track.range()?.description
        else { return }
        
        let distance = track.distance
        let speed = (track.averageSpeed() ?? track.speed.last) ?? 0
        let roundedSpeed = (speed  * 10).rounded() / 10
        
        trackLabel.text = "\(Int(distance.rounded()))" //meters
        timeLabel.text = "\(duration)"
        speedLabel.text = "\(roundedSpeed)" //m/s
    }
    
    @IBAction func startTrackingAction(_ sender: UIButton) {
        
        switch isTracking {
        case false, .none:
            removeTrack()
            
            isTracking = true
            locationManager?.requestLocation()
            
            route = GMSPolyline()
            routePath = GMSMutablePath()
            route?.map = mapView
            
            locationManager?.startUpdatingLocation()
            
            sender.setTitle("Finish", for: .normal)
        case true:
            isTracking = false
            sender.setTitle("Start", for: .normal)
        case .some(_):
            print(#function)
        }
        
        
    }
    
}

extension ViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        zoom = mapView.camera.zoom
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    fileprivate func moveMap(_ location: CLLocation) {
        let postion = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: zoom)
        mapView.animate(to: postion)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(locations)
        
        guard let location = locations.last else { return }
        
        switch isTracking {
        case .none:
            moveMap(location)
            
            self.locationManager?.stopUpdatingLocation()
        case true:
            if track == nil {
                track = Track()
                track?.start = GMSMarker(position: location.coordinate)
                track?.start?.map = mapView
                //addMarker(coordinate: location.coordinate)
            }
            
            routePath?.add(location.coordinate)
            route?.path = routePath
            
            if let lastLocation = track?.lastLocation {
                track?.distance += location.distance(from: lastLocation)
                track?.lastLocation = location
                track?.speed.append(location.speed)
            }
            
            moveMap(location)
            trackInfo()
        case false:
            track?.finish = GMSMarker(position: location.coordinate)
            track?.finish?.map = mapView
            //addMarker(coordinate: location.coordinate)
            
            routePath?.add(location.coordinate)
            route?.path = routePath
            
            self.locationManager?.stopUpdatingLocation()
            trackInfo()
        case .some(_):
            print(#function)
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

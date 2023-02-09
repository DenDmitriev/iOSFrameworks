//
//  TrackViewController.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 30.01.2023.
//

import UIKit
import GoogleMaps
import RealmSwift

class TrackViewController: UIViewController {
    
    var onUser: (() -> Void)?
    var onTracks: (() -> Void)?
    
    var usselesExampleVariable: String = ""
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var uiView: UIView!
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var trackActionButton: UIButton!
    
    @IBOutlet weak var uiStackView: UIStackView!
    @IBOutlet weak var uiViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userImageView: UIImageView!
    
    var locationManager: CLLocationManager?
    var route: GMSPolyline? //линия пути
    var routePath: GMSMutablePath? //пройденный путь/маршрут
    
    var trackManager: TrackManager?
    var zoom: Float = 15
    var strokeWidth: CGFloat = 10
    
    var uiViewDefaultConstraint: CGFloat = 0
    var uiViewDownOffset: CGFloat = 0
    var uiViewUp: CGPoint = CGPoint()
    var uiViewDown: CGPoint = CGPoint()
    
    var realmService: RealmService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(usselesExampleVariable)
        
        configureUI()
        configureMap()
        configureLocationManager()
    }
    
    //MARK: - Configure
    
    private func configureUIView() {
        uiView.layer.cornerRadius = 16
        let color = uiView.backgroundColor
        uiView.backgroundColor = color?.withAlphaComponent(0.9)
        uiView.layer.shadowColor = UIColor.black.cgColor
        uiView.layer.shadowRadius = 4
        uiView.layer.shadowOpacity = 0.2
        
        let countViews = CGFloat(uiStackView.arrangedSubviews.count)
        let countVisibaleViews: CGFloat = 2
        let heightView = uiStackView.frame.height
        let spacing = uiStackView.spacing
        let safeArea: CGFloat = 16
        
        uiViewDownOffset = (countViews - countVisibaleViews) * (((heightView - spacing * (countViews - 1)) / countViews) + uiViewBottomConstraint.constant + safeArea)
        uiViewUp = uiView.center
        uiViewDown = CGPoint(x: uiView.center.x, y: uiView.center.y + uiViewDownOffset)
        uiViewDefaultConstraint = uiViewBottomConstraint.constant
    }
    
    private func configureUserButton() {
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        userImageView.layer.masksToBounds = true
        userImageView.layer.borderColor = UIColor.gray.cgColor
        userImageView.layer.borderWidth = 2
    }
    
    private func configureUI() {
        
        configureUIView()
        
        let labels = [trackLabel, timeLabel, speedLabel]
        labels.forEach { label in
            label?.adjustsFontSizeToFitWidth = true
        }
        
        trackActionButton.configurationUpdateHandler = { button in
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30, weight: .heavy)]
            var attributedText = AttributedString("Title")
            switch Session.shared.isTracking {
            case true:
                attributedText = AttributedString(NSLocalizedString("Finish", comment: "Some buttons"), attributes: AttributeContainer(attributes))
                button.tintColor = .systemPurple
            default:
                attributedText = AttributedString(NSLocalizedString("Start", comment: "Some buttons"), attributes: AttributeContainer(attributes))
                button.tintColor = .systemBlue
            }
            button.configuration?.attributedTitle = attributedText
        }
        
        configureUserButton()
        
    }
    
    private func configureMap() {
        mapView.isMyLocationEnabled = true
        let camera = GMSCameraPosition.camera(withTarget: mapView.myLocation?.coordinate ?? CLLocationCoordinate2D(latitude: -180, longitude: -180), zoom: zoom)
        mapView.camera = camera
        mapView.padding = UIEdgeInsets(top: 64, left: 32, bottom: (uiView.frame.height + 32), right: 32)
        
        mapView.delegate = self
        
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
    }
    
    private func configureLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = !(Session.shared.isTracking ?? false)
        //locationManager?.requestWhenInUseAuthorization()
        locationManager?.requestAlwaysAuthorization()
        
        locationManager?.requestLocation()
    }
    
    //MARK: - Actions
    
    @IBAction func didTapUserAction(_ sender: UITapGestureRecognizer) {
        if Session.shared.isTracking ?? false {
            alertIsTracking {
                print(#function)
            }
        } else {
            onUser?()
        }
    }
    
    private func alertIsTracking(operation: @escaping (() -> ())) {
        let alertController = UIAlertController(
            title: "You are in tracking",
            message: "Before opening you must finish the current.",
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "Ok", style: .default) { _ in
            operation()
        }
        alertController.addAction(action)
        
        self.present(alertController, animated: true)
    }
    
    @IBAction func startTrackingAction(_ sender: UIButton) {
        
        switch Session.shared.isTracking {
        case true:
            Session.shared.isTracking = false
            
            locationManager?.stopMonitoringSignificantLocationChanges()
        default:
            removeTrack()
            
            Session.shared.isTracking = true
            
            locationManager?.startMonitoringSignificantLocationChanges()
            
            stopwatch()
            
            locationManager?.requestLocation()
            
            createRoute()
            
            locationManager?.startUpdatingLocation()
            
            UIView.animate(withDuration: 0.3) {
                self.uiView.center = self.uiViewDown
            }
            
            if uiViewBottomConstraint.constant == uiViewDefaultConstraint {
                uiViewBottomConstraint.constant -= uiViewDownOffset
            }
        }
    }
    @IBAction func tracksDidTaped(_ sender: UIButton) {
        self.onTracks?()
    }
    
    private func stopwatch() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if Session.shared.isTracking != true {
                timer.invalidate()
            }
            self.timeLabel.text = self.trackManager?.stringDuration()
        }
    }
    
    @IBAction func uiViewPanGesture(_ sender: UIPanGestureRecognizer) {
        let velocity = sender.velocity(in: uiView)
        
        if sender.state == .ended {
            if velocity.y > 0 && uiViewBottomConstraint.constant == uiViewDefaultConstraint {
                UIView.animate(withDuration: 0.3) {
                    self.uiView.center = self.uiViewDown
                }
                uiViewBottomConstraint.constant -= uiViewDownOffset
            } else if velocity.y < 0 && uiViewBottomConstraint.constant == (uiViewDefaultConstraint - uiViewDownOffset) {
                UIView.animate(withDuration: 0.3) {
                    self.uiView.center = self.uiViewUp
                }
                uiViewBottomConstraint.constant += uiViewDownOffset
            }
        }
    }
    
    //MARK: - Maps functions
    
    private func removeTrack() {
        mapView.clear()
        trackManager = nil
        //route?.map = nil
        //route?.path = nil
        //routePath = nil
    }
    
    private func trackInfo() {
        guard let trackManager = trackManager else { return }
        
        if Session.shared.isTracking != true {
            timeLabel.text = "\(trackManager.stringDuration())" //00:00
        }
        trackLabel.text = "\(trackManager.stringDistance())" //m
        speedLabel.text = "\(trackManager.stringSpeed())" //m/s
    }
    
    private func cameraTo(_ location: CLLocation) {
        let postion = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: self.zoom)
        self.mapView.animate(to: postion)
    }
    
    
    private func cameraFitTrack() {
        guard let path = route?.path else { return }

        let bounds = GMSCoordinateBounds(path: path)

        self.mapView.animate(with: .fit(bounds, with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)))
    }
    
    private func createRoute(for locations: [CLLocation]? = nil) {
        route = GMSPolyline()
        let spans: [GMSStyleSpan] = []
        route?.spans = spans
        routePath = GMSMutablePath()
        route?.strokeWidth = strokeWidth
        route?.map = mapView
        
        locations?.forEach { location in
            routePath?.add(location.coordinate)
            let span = GMSStyleSpan.getColor(by: location.speed)
            route?.spans?.append(span)
        }
        route?.path = routePath
    }
    
    private func routeUpdate(location: CLLocation) {
        routePath?.add(location.coordinate)
        route?.path = routePath
        //Polyline color
        let span = GMSStyleSpan.getColor(by: location.speed)
        route?.spans?.append(span)
    }
    
    //MARK: - Realm Data
    
    private func saveTrack(from trackManager: TrackManager?) {
        if realmService == nil {
            realmService = RealmService()
            realmService?.getPathForDataFile() //to console
        }
        
        guard
            let trackManager = trackManager,
            let startTime = trackManager.startTime,
            let finishTime = trackManager.finishTime
        else { return }
        
        let locations = MapsManager.locationAdapter(trackManager.locations)
        
        realmService?.addTrack(startTime: startTime, finishTime: finishTime, distance: trackManager.distance, locations: locations)
    }
    
}

extension TrackViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        zoom = mapView.camera.zoom
    }
}

extension TrackViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(locations)
        
        guard let location = locations.last else { return }
        
        switch Session.shared.isTracking {
        case true:
            if trackManager == nil {
                trackManager = TrackManager()
                trackManager?.startTime = Date.now
                let marker = GMSMarker(position: location.coordinate)
                marker.appearAnimation = .pop
                trackManager?.start = marker
                trackManager?.start?.map = mapView
            }
            
            routeUpdate(location: location)
            
            trackManager?.locations.append(location)
            
            trackInfo()
            
            cameraTo(location)
        case false:
            self.locationManager?.stopUpdatingLocation()
            
            if trackManager?.finishTime == nil {
                trackManager?.finishTime = Date.now
                let marker = GMSMarker(position: location.coordinate)
                marker.appearAnimation = .pop
                trackManager?.finish = marker
                trackManager?.finish?.map = mapView
                
                routeUpdate(location: location)
                
                trackInfo()
                
                saveTrack(from: trackManager)
            }
        default:
            self.locationManager?.stopUpdatingLocation()
            
            cameraTo(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension TrackViewController: TrackViewControllerDelegate {
    
    func update(track: Track) {
        print(#function)
        
        removeTrack()
        
        let locations = MapsManager.locationAdapter(track.locations.sorted { $0.timestamp < $1.timestamp })
        
        self.trackManager = TrackManager(
            startTime: track.startTime,
            finishTime: track.finishTime,
            locations: locations,
            distance: track.distance
        )
        
        guard
            let startLocation = trackManager?.locations.first,
            let finishLoaction = trackManager?.locations.last
        else { return }
        
        trackManager?.start = GMSMarker(position: startLocation.coordinate)
        trackManager?.start?.map = mapView
        trackManager?.finish = GMSMarker(position: finishLoaction.coordinate)
        trackManager?.finish?.map = mapView
        
        createRoute(for: locations)
        
        trackInfo()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.cameraFitTrack()
        }
    }
}

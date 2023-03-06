//
//  TrackViewController.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 30.01.2023.
//

import UIKit
import GoogleMaps
import RealmSwift
import RxSwift
import RxCocoa

class TrackViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var uiView: UIView!
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var trackActionButton: UIButton!
    @IBOutlet weak var uiViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var userImageView: UIImageView!
    
    lazy var locationIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let diameter = 32.0
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: diameter),
            imageView.heightAnchor.constraint(equalToConstant: diameter)
        ])
        imageView.layer.cornerRadius = diameter / 2
        return imageView
    }()
    
    var viewModel = TrackViewModel()
    var trackManager: TrackManager?
    let disposeBag = DisposeBag()
    
    var onUser: (() -> Void)?
    var onTracks: (() -> Void)?
    
    var locationMarker: GMSMarker?
    var startMarker: GMSMarker?
    var finishMarker: GMSMarker?
    let locationManager = LocationManager.instance
    var route: GMSPolyline? //линия пути
    var routePath: GMSMutablePath? //пройденный путь/маршрут
    var zoom: Float = 15
    var strokeWidth: CGFloat = 10
    
    var uiViewDefaultConstraint: CGFloat = 0
    var uiViewDownOffset: CGFloat = 0
    var uiViewUp: CGPoint = CGPoint()
    var uiViewDown: CGPoint = CGPoint()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureMap()
        configureLocationManager()
        configureTrack()
    }
    
    //MARK: - Configure
    
    private func configureUI() {
        
        viewModel = TrackViewModel()
        
        //View UI
        uiView.layer.cornerRadius = 16
        let color = uiView.backgroundColor
        uiView.backgroundColor = color?.withAlphaComponent(0.9)
        uiView.layer.shadowColor = UIColor.black.cgColor
        uiView.layer.shadowRadius = 4
        uiView.layer.shadowOpacity = 0.2
        
        //Labels
        let labels = [trackLabel, timeLabel, speedLabel]
        labels.forEach { label in
            label?.adjustsFontSizeToFitWidth = true
        }
        
        //Action button
        Session.shared.isTracking
            .bind { [weak self] isTracking in
                let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30, weight: .heavy)]
                let title = (isTracking ?? false) ? "Finish" : "Start"
                let attributedText = AttributedString(NSLocalizedString(title, comment: "Some buttons"), attributes: AttributeContainer(attributes))
                self?.trackActionButton.configuration?.attributedTitle = attributedText
                self?.trackActionButton.tintColor = (isTracking ?? false) ? .systemPurple : .systemBlue
            }
            .disposed(by: disposeBag)
        
        //User buttom
        let userImage = viewModel.getUserImage()
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        userImageView.layer.masksToBounds = true
        userImageView.layer.borderColor = UIColor.white.cgColor
        userImageView.layer.borderWidth = 2
        userImageView.image = userImage
        
        //User location icon
        locationIcon.image = userImage
    }
    
    private func configureMap() {
        mapView.isMyLocationEnabled = true
        let myLocation = mapView.myLocation?.coordinate ?? CLLocationCoordinate2D(latitude: -180, longitude: -180)
        let camera = GMSCameraPosition.camera(withTarget: myLocation, zoom: zoom)
        mapView.camera = camera
        mapView.padding = UIEdgeInsets(top: 64, left: 32, bottom: (uiView.frame.height + 32), right: 32)
        mapView.delegate = self
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        
        locationMarker = GMSMarker()
        locationMarker?.position = myLocation
        locationMarker?.iconView = locationIcon
        locationMarker?.groundAnchor.y -= 0.5
        locationMarker?.map = mapView
    }
    
    private func configureLocationManager() {
        locationManager.location
            .asObservable()
            .bind { [weak self] location in
                guard let location = location else { return }
                
                self?.moveLocationMarker(to: location.coordinate)
                
                do {
                    let isTracking = try Session.shared.isTracking.value()
                    
                    switch isTracking {
                    case true:
                        if self?.trackManager == nil {
                            self?.trackManager = TrackManager(startTime: Date.now)
                            self?.startMarker = self?.marker(on: location.coordinate)
                        }
                        self?.routeUpdate(location: location)
                        self?.trackManager?.locations.append(location)
                        self?.trackInfo()
                        self?.cameraTo(location)
                        
                    case false:
                        //self?.locationManager.locationManager.stopUpdatingLocation()
                        if self?.trackManager?.finishTime == nil {
                            self?.trackManager?.finishTime = Date.now
                            self?.finishMarker = self?.marker(on: location.coordinate)
                            self?.routeUpdate(location: location)
                            self?.trackInfo()
                            self?.viewModel.saveTrack(from: self?.trackManager)
                        }
                        
                    default:
                        //self?.locationManager.locationManager.stopUpdatingLocation()
                        self?.cameraTo(location)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
            .disposed(by: disposeBag)
    }
    
    func configureTrack() {
        guard
            let startLocation = trackManager?.locations.first,
            let finishLoaction = trackManager?.locations.last
        else { return }
        
        startMarker = marker(on: startLocation.coordinate)
        finishMarker = marker(on: finishLoaction.coordinate)
        
        createRoute(for: trackManager?.locations)
        
        trackInfo()
        
        self.cameraFitTrack()
    }
    
    //MARK: - Actions
    
    @IBAction func didTapUserAction(_ sender: UITapGestureRecognizer) {
        do {
            let isTracking = try Session.shared.isTracking.value()
            if isTracking ?? false {
                alertIsTracking()
            } else {
                onUser?()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func alertIsTracking() {
        self.present(viewModel.alertTracking(), animated: true)
    }
    
    @IBAction func startTrackingAction(_ sender: UIButton) {
        do {
            let isTracking = try Session.shared.isTracking.value()
            
            switch isTracking {
            case true:
                Session.shared.isTracking.onNext(false)
                locationManager.locationManager.stopMonitoringSignificantLocationChanges()
            default:
                removeTrackFromMap()
                
                Session.shared.isTracking.onNext(true)
                locationManager.locationManager.startMonitoringSignificantLocationChanges()
                stopwatch()
                createRoute()
                locationManager.locationManager.startUpdatingLocation()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func tracksDidTaped(_ sender: UIButton) {
        self.onTracks?()
    }
    
    private func stopwatch() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let isTracking = try? Session.shared.isTracking.value()
            
            if isTracking != true {
                timer.invalidate()
            }
            self.timeLabel.text = self.trackManager?.stringDuration()
        }
    }
    
    //MARK: - Maps functions
    
    private func marker(on coordinate: CLLocationCoordinate2D) -> GMSMarker {
        let marker = GMSMarker(position: coordinate)
        marker.appearAnimation = .pop
        marker.map = mapView
        return marker
    }
    
    func removeTrackFromMap() {
        mapView.clear()
        trackManager = nil
    }
    
    private func trackInfo() {
        guard let trackManager = trackManager else { return }
        
        let isTracking = try? Session.shared.isTracking.value()
        
        if isTracking != true {
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
    
    private func moveLocationMarker(to position: CLLocationCoordinate2D) {
        locationMarker?.position = position
        locationMarker?.map = mapView
    }
    
}

extension TrackViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        zoom = mapView.camera.zoom
    }
}

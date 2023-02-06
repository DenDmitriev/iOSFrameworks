//
//  Track.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 31.01.2023.
//

import Foundation
import GoogleMaps

class Track {
    
    var start: GMSMarker? {
        willSet {
            newValue?.title = "Start"
            startTime = Date.now
            newValue?.snippet = description(location: newValue?.position, date: Date.now)
            if let location = newValue?.position {
                lastLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            }
        }
    }
    var finish: GMSMarker? {
        willSet {
            newValue?.title = "Finish"
            finishTime = Date.now
            newValue?.snippet = description(location: newValue?.position, date: Date.now)
        }
    }
    
    var startTime: Date?
    var finishTime: Date?
    
    var distance: Double = 0
    var lastLocation: CLLocation?
    
    var speed: [Double] = []
    
    func averageSpeed() -> Double? {
        if speed.isEmpty {
            return nil
        } else {
            var total: Double = 0
            speed.forEach { total += $0 }
            let average = total / Double(speed.count)
            return average
        }
    }
    
    private func description(location: CLLocationCoordinate2D?, date: Date) -> String {
        guard let location = location else { return "" }
        
        let latitude = location.latitude
        let longitude = location.longitude
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        let description: String = formatter.string(from: date) + "\n\(latitude)" + ", \(longitude)"
        return description
    }
    
    private func clear() {
        start?.map = nil
        finish?.map = nil
        start = nil
        finish = nil
    }
    
    func range() -> String? {
        guard
            let start = startTime
        else { return nil }
        //let range = start...finish
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        let duration = formatter.string(from: start, to: finishTime ?? Date.now)
        
        return duration
    }
    
    deinit {
        clear()
    }
}

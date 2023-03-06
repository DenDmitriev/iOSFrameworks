//
//  TrackViewModel.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 06.03.2023.
//

import UIKit
import GoogleMaps

class TrackViewModel {
    
    var realmService: RealmService?
    
    func getUserImage() -> UIImage? {
        guard
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("user", conformingTo: .image)
        else { return nil }
        
        do {
            let data = try Data(contentsOf: path)
            let image = UIImage(data: data)
            return image
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func alertTracking() -> UIAlertController {
        let alertController = UIAlertController(
            title: "You are in tracking",
            message: "Before opening you must finish the current.",
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "Ok", style: .default)
        alertController.addAction(action)
                                   
        return alertController
    }
    
    //MARK: - Realm Data
    
    func saveTrack(from trackManager: TrackManager?) {
        if realmService == nil {
            realmService = RealmService()
            realmService?.getPathForDataFile() //to console
        }
        
        guard
            let trackManager = trackManager,
            let startTime = trackManager.startTime,
            let finishTime = trackManager.finishTime
        else { return }
        
        realmService?.addTrack(startTime: startTime, finishTime: finishTime, distance: trackManager.distance, locations: trackManager.locations.locations)
    }
}

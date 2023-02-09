//
//  RealmService.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 03.02.2023.
//

import Foundation
import RealmSwift

class RealmService {
    
    var realm = try? Realm()
    
    func getPathForDataFile() {
        let string = "Realm data base created on path - " + (realm?.configuration.fileURL?.absoluteString ?? "no realm file")
        print(string)
    }
    
    func addTrack(startTime: Date, finishTime: Date, distance: Double, locations: [Location]) {
        guard let realm = realm else { return }
        
        do {
            let track = Track()
            track.startTime = startTime
            track.finishTime = finishTime
            track.distance = distance
            
            try realm.write {
                realm.add(track)
                realm.add(locations)
                
                locations.forEach { location in
                    location.track = track
                }
                
                track.locations.append(objectsIn: locations)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getTracks(sorting: Sorting) -> [Track]? {
        guard let realm = realm else { return nil }
        
        let tracks = realm.objects(Track.self)
        
        switch sorting {
        case .new:
            return tracks.sorted { $0.startTime > $1.startTime }
        case .old:
            return tracks.sorted { $0.startTime < $1.startTime }
        }
    }
    
    enum Sorting {
        case old, new
    }
    
    func getLocations(for track: Track) -> [Location]? {
        guard let realm = realm else { return nil }
        
        let locations = realm.objects(Location.self).where {
            $0.track == track
        }
        return locations.sorted { $0.timestamp < $1.timestamp }
        
    }
    
    func removeTrack(track: Track) {
        guard let realm = realm else { return }
        
        if let locations = getLocations(for: track) {
            do {
                try realm.write {
                    realm.delete(locations)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        do {
            try realm.write {
                realm.delete(track)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func removeAll() {
        guard let realm = realm else { return }
        
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print(error)
        }
    }
}

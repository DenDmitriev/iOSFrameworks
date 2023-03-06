//
//  UserViewModel.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 06.03.2023.
//

import Foundation
import UIKit

class UserViewModel {
    
    var realmService: RealmService?
    
    init() {
        self.realmService = RealmService()
    }
    
    func getUser() -> User? {
        guard let login = UserDefaults.standard.string(forKey: "login") else {
            return nil
        }
        return realmService?.getUser(login: login)
    }
    
    func saveImage(image: UIImage) {
        guard
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }
        
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            let imagePath = path.appendingPathComponent("user", conformingTo: .image)
            do {
                try jpegData.write(to: imagePath)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func getUserImage() -> UIImage? {
        guard
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return nil }
        
        let imagePath = path.appendingPathComponent("user", conformingTo: .image)
        
        do {
            let data = try Data(contentsOf: imagePath)
            let image = UIImage(data: data)
            return image
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
    }
}

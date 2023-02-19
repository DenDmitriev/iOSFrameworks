//
//  UserCoordinator.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 09.02.2023.
//

import UIKit

class UserCoordinator: Coordinator {
    
    var rootController: UINavigationController?
    
    var onFinishFlow: (() -> Void)?
    
    override func start() {
        showUserSettings()
    }
    
    private func showUserSettings() {
        guard let controller = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "UserViewController") as? UserViewController else { return }
        
        controller.onLogout = { [weak self] in
            UserDefaults.standard.set(false, forKey: "isLogin")
            self?.onFinishFlow?()
        }
        
        controller.toTrack = { [weak self] stringValue in
            print(stringValue)
            self?.onFinishFlow?()
        }
        
        let rootController = UINavigationController(rootViewController: controller)
        setAsRoot(controller)
        self.rootController = rootController
    }
}


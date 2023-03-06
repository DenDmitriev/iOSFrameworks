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
        guard let controller = UIStoryboard(name: "User", bundle: Bundle.main).instantiateViewController(withIdentifier: "UserViewController") as? UserViewController else { return }
        
        controller.coordinator = self
        
        controller.onLogout = { [weak self] in
            UserDefaults.standard.set(false, forKey: "isLogin")
            self?.onFinishFlow?()
        }
        
        controller.toTrack = { [weak self] stringValue in
            print(stringValue)
            self?.onFinishFlow?()
        }
        
        let rootController = UINavigationController(rootViewController: controller)
        setAsRoot(rootController)
        self.rootController = rootController
    }
    
    func toPicker() {
        guard let controller = rootController?.viewControllers.last as? UserViewController else { return }
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = controller
        picker.allowsEditing = true
        rootController?.viewControllers.last?.present(picker, animated: true)
    }
}


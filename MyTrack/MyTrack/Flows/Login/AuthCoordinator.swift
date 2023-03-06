//
//  AuthCoordinator.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 09.02.2023.
//

import UIKit

class AuthCoordinator: Coordinator {
    
    var rootController: UINavigationController?
    
    var onFinishFlow: (() -> Void)?
    
    override func start() {
        showLoginModule()
    }
    
    private func showLoginModule() {
        guard let controller = UIStoryboard(name: "Auth", bundle: Bundle.main).instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else { return }
        
        controller.onRecover = { [weak self] in
            self?.showRecoverModule()
        }
        
        controller.onLogin = { [weak self] user in
            print(user)
            UserDefaults.standard.set(user.login, forKey: "login")
            self?.onFinishFlow?()
        }
        
        let rootController = UINavigationController(rootViewController: controller)
        
        setAsRoot(rootController)
        
        self.rootController = rootController
        
    }
    
    private func showRecoverModule() {
        let controller = UIStoryboard(name: "Auth", bundle: nil).instantiateViewController(withIdentifier: "RecoverViewController")
        rootController?.pushViewController(controller, animated: true)
    }
}

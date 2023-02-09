//
//  TrackCoordinator.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 09.02.2023.
//

import UIKit

class TrackCoordinator: Coordinator {
    var rootController: UINavigationController?
    
    var onFinishFlow: (() -> Void)?
    
    override func start() {
        showTrackModule()
    }
    
    private func showTrackModule() {
        guard let controller = UIStoryboard(name: "Track", bundle: nil).instantiateViewController(withIdentifier: "TrackViewController") as? TrackViewController else { return }
        
        controller.onUser = { [weak self] in
            self?.showUserModule()
        }
        
        controller.onTracks = { [weak self] in
            self?.showTracksModule()
        }
        
        let rootController = UINavigationController(rootViewController: controller)
        setAsRoot(rootController)
        self.rootController = rootController
    }
    
    private func showUserModule() {
        let coordinator = UserCoordinator()
        
        coordinator.onFinishFlow = { [weak self, weak coordinator] in
            self?.removeDependency(coordinator)
            self?.onFinishFlow?()
            /*
            if UserDefaults.standard.bool(forKey: "isLoggin") {
                self?.start()
            } else {
                self?.onFinishFlow?()
            }
            */
        }
        
        addDependency(coordinator)
        coordinator.start()
    }
    
    private func showTracksModule() {
        guard
            let controller = UIStoryboard(name: "Track", bundle: nil).instantiateViewController(withIdentifier: "TrackCollectionViewController") as? TrackCollectionViewController,
            let lastController = rootController?.viewControllers.last as? TrackViewController
        else { return }
        
        controller.delegate = lastController
        rootController?.pushViewController(controller, animated: true)
    }
}

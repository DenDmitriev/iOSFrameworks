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
    
    func start(with track: Track?) {
        showTrackModule(with: track)
    }
    
    override func start() {
        showTrackModule()
    }
    
    private func showTrackModule(with track: Track? = nil) {
        guard let controller = UIStoryboard(name: "Track", bundle: nil).instantiateViewController(withIdentifier: "TrackViewController") as? TrackViewController else { return }
        
        controller.onUser = { [weak self] in
            self?.showUserModule()
        }
        
        controller.onTracks = { [weak self] in
            self?.showTracksModule()
        }
        
        if let track = track {
            controller.trackManager = TrackManager(track: track)
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
        }
        
        addDependency(coordinator)
        coordinator.start()
    }
    
    private func showTracksModule() {
        let coordinator = TracksCoordinator()
        
        coordinator.onFinishFlow = { [weak self, weak coordinator] track in
            self?.removeDependency(coordinator)
            self?.start(with: track)
        }
        
        addDependency(coordinator)
        coordinator.start()
    }
}

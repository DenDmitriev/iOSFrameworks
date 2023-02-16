//
//  TracksCoordinator.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 16.02.2023.
//

import UIKit

class TracksCoordinator: Coordinator {
    
    var rootController: UINavigationController?
    
    var onFinishFlow: ((Track?) -> Void)?
    
    override func start() {
        showTracksModule()
    }
    
    private func showTracksModule() {
        guard let controller = UIStoryboard(name: "Track", bundle: nil).instantiateViewController(withIdentifier: "TrackCollectionViewController") as? TrackCollectionViewController else { return }
        
        let rootController = UINavigationController(rootViewController: controller)
        setAsRoot(rootController)
        self.rootController = rootController
        
        controller.toTrack = { [weak self] track in
            self?.onFinishFlow?(track)
        }
    }
}

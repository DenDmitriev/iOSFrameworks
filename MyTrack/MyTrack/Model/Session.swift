//
//  Session.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 03.02.2023.
//

import UIKit

class Session {
    
    static let shared = Session()
    
    var isTracking: Bool?
    
    enum Style: Int {
        case walk, run, bicycle
    }
    
    var style: Style = .walk
    
    private init() {}
    
    func subscribePrivateDelegate(for controller: PrivateDelegate) {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let sceneDelegate = windowScene.delegate as? SceneDelegate
        else { return }
        
        sceneDelegate.privateDelegate = controller
    }
}

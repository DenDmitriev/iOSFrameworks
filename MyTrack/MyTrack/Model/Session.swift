//
//  Session.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 03.02.2023.
//

import Foundation

class Session {
    
    static let shared = Session()
    
    var isTracking: Bool?
    
    private init() {}
}

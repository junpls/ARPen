//
//  Plugin.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import ARKit

/**
 The Plugin protocol. If you want to write a new plugin you must use this protocol.
 */
protocol Plugin {
    
    var pluginImage : UIImage? { get }
    var pluginIdentifier : String { get }
    var scene: PenScene { get set }
    
}

protocol PenDelegate {
    func onIdleMovement(to position: SCNVector3)
    func onPenClickStarted(at position: SCNVector3, startedButton: Button)
    func onPenMoved(to position: SCNVector3, clickedButtons: [Button])
    func onPenClickEnded(at position: SCNVector3, releasedButton: Button)
}

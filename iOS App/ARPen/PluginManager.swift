//
//  PluginManager.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import ARKit

protocol PluginManagerDelegate {
    func arKitInitialiazed()
    func penConnected()
    func penFailed()
}

/**
 The PluginManager holds every plugin that is used. Furthermore the PluginManager holds the AR- and PenManager.
 */
class PluginManager: ARManagerDelegate, PenManagerDelegate {

    var arManager: ARManager
    var arPenManager: PenManager
    var buttons: [Button: Bool] = [.Button1: false, .Button2: false, .Button3: false]
    var plugins: [Plugin]
    var activePlugin: Plugin? {
        didSet {
            if activePlugin is PenTrackingDelegate {
                arManager.scene?.penTrackingDelegate = activePlugin as? PenTrackingDelegate
            }
        }
    }
    var delegate: PluginManagerDelegate?
    private var penClicked = false
    
    /**
     inits every plugin
     */
    init(scene: PenScene) {
        self.arManager = ARManager(scene: scene)
        self.plugins  = [PieMenuPlugin(scene: scene)]
        self.arPenManager = PenManager()
        self.activePlugin = plugins.first
        self.arManager.delegate = self
        self.arPenManager.delegate = self
        
    }
    
    /**
     Callback from PenManager
     */
    func button(_ button: Button, pressed: Bool) {
        let started = self.buttons[button] != pressed && pressed
        let released = self.buttons[button] != pressed && !pressed
        self.buttons[button] = pressed
        if let plugin = self.activePlugin {
            if plugin is PenDelegate {
                if started {
                    (plugin as! PenDelegate).onPenClickStarted(at: (arManager.scene?.pencilPoint.position)!, startedButton: button)
                } else if released {
                    (plugin as! PenDelegate).onPenClickEnded(at: (arManager.scene?.pencilPoint.position)!, releasedButton: button)
                }
            }
        }
        var oneButtonClicked = false
        for (_, clicked) in buttons {
            if clicked {
                oneButtonClicked = true
            }
        }
        penClicked = oneButtonClicked
    }
    
    /**
     Callback from PenManager
     */
    func connect(successfully: Bool) {
        if successfully {
            self.delegate?.penConnected()
        } else {
            self.delegate?.penFailed()
        }
    }
    
    /**
     Callback form ARCamera
     */
    func didChangeTrackingState(cam: ARCamera) {
        switch cam.trackingState {
        case .normal:
            self.delegate?.arKitInitialiazed()
        default:
            break
        }
    }
    
    /**
     This is the callback from ARManager.
     */
    func finishedCalculation() {
        if let plugin = self.activePlugin, plugin is PenDelegate {
            if penClicked {
                (plugin as! PenDelegate).onPenMoved(to: (arManager.scene?.pencilPoint.position)!, clickedButtons: Array(self.buttons.filter { $0.value == true }.keys))
            } else {
                (plugin as! PenDelegate).onIdleMovement(to: (arManager.scene?.pencilPoint.position)!)
            }
        }
    }
}


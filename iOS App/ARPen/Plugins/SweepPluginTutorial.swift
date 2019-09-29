//
//  SweepPluginTutorial.swift
//  ARPen
//
//  Created by Jan Benscheid on 29.9.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
 This class should demonstrate the exemplary usage of the geometry manipulation code.
 */
class SweepPluginTutorial: Plugin, UIButtonPlugin {
    
    // This plugin only passes the UI buttons to the `curve designer`, which labels the buttons.
    // Part of `UIButtonPlugin` protocol
    var penButtons: [Button : UIButton]! {
        didSet {
            curveDesigner.injectUIButtons(self.penButtons)
        }
    }
    
    // Part of `UIButtonPlugin` protocol
    var undoButton: UIButton!
    
    var pluginImage: UIImage?
    var pluginIdentifier: String = "Sweep (Profile + Path)"
    var currentScene: PenScene?
    var currentView: ARSCNView?
    
    /// Paths, which are not yet used to create a sweep
    private var freePaths: [ARPPath] = [ARPPath]()

    /// The curve designer "sub-plugin", responsible for the interactive path creation
    private var curveDesigner: CurveDesigner

    init() {
        // Initialize curve designer
        curveDesigner = CurveDesigner()
        // Listen to the `didCompletePath` event.
        curveDesigner.didCompletePath = self.didCompletePath
    }
    
    /// Called whenever the user switches to the plugin, or returns from the settings with the plugin selected.
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentView = view
        self.currentScene = scene
        self.undoButton.addTarget(self, action: #selector(undo), for: .touchUpInside)
    }
    
    func deactivatePlugin() {
        
    }
    
    @objc func undo() {
        curveDesigner.undo()
    }
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        curveDesigner.update(scene: scene, buttons: buttons)
    }

    func didCompletePath(_ path: ARPPath) {
        // Add newly completed path to set of free paths.
        freePaths.append(path)
        
        // Look in the free paths for one that is closed and one which is open and has more than one point.
        // Use them to create a sweep.
        if let profile = freePaths.first(where: { $0.closed }),
            let spine = freePaths.first(where: { !$0.closed && $0.points.count > 1 }) {
            
            // Geometry creation may take time and should be done asynchronous.
            DispatchQueue.global(qos: .userInitiated).async {
                
                // Only planar paths can be used as profile for sweeping.
                profile.flatten()
                
                // Try to create a sweep
                if let sweep = try? ARPSweep(profile: profile, path: spine) {
                    // Attach the swept object to the scene synchronous.
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(sweep)
                        // Remove the links to the used paths from the set of free paths.
                        // You don't need to (and must not) delete the paths themselves. When creating the sweep, they became children of the `ARPSweep` object in order to allow for hierarchical editing.
                        self.freePaths.removeAll(where: { $0 === profile || $0 === spine })
                    }
                }
            }
        }
    }
}

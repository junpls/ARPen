//
//  LinePlugin.swift
//  ARPen
//
//  Created by Jan on 04.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class SweepPluginTwoProfiles: Plugin {
    
    var pluginImage: UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Sweep (Two Profiles)"
    var currentScene: PenScene?
    var currentView: ARSCNView?
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    
    private var freePaths: [ARPPath] = [ARPPath]()
    private var busy: Bool = false
    
    private var curveDesigner: CurveDesigner
    
    init() {
        curveDesigner = CurveDesigner()
        curveDesigner.didCompletePath = self.didCompletePath;
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentView = view
        self.currentScene = scene
    }
    
    func deactivatePlugin() {
        
    }
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        curveDesigner.update(scene: scene, buttons: buttons)
    }
    
    func didCompletePath(_ path: ARPPath) {
        freePaths.append(path)
        if let profile1 = freePaths.first(where: { $0.closed }),
            let profile2 = freePaths.last(where: { $0.closed }),
            profile1 !== profile2 {
            
            profile1.flatten()
            profile2.flatten()
            
            let center1 = ARPPathNode(profile1.getCenter())
            let center2 = ARPPathNode(profile2.getCenter())

            let spine = ARPPath(points: [center1, center2], closed: false)
            self.currentScene?.drawingNode.addChildNode(spine)
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let sweep = try? ARPSweep(profile: profile1, path: spine) {
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(sweep)
                        profile2.removeFromParentNode()
                        self.freePaths.removeAll(where: { $0 === profile1 || $0 === profile2 })
                    }
                }
            }
        }
    }
}

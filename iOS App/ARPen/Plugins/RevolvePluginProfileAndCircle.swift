//
//  RevolvePlugin.swift
//  ARPen
//
//  Created by Jan on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class RevolvePluginProfileAndCircle: Plugin {
    
    var pluginImage: UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Revolve (Profile + Circle)"
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
        if let profile = freePaths.first(where: { !$0.closed && $0.points.count >= 2 }),
            let circle = freePaths.first(where: { $0.closed }) {
            
            DispatchQueue.global(qos: .userInitiated).async {
                profile.flatten()
                circle.flatten()
                
                let axisDir = circle.getPC1()
                let axisPos = OCCTAPI.shared.circleCenter(circle.getPointsAsVectors())
                let axisPath = ARPPath(points: [
                    ARPPathNode(axisPos),
                    ARPPathNode(axisPos + axisDir)
                    ], closed: false);
                if let revolution = try? ARPRevolution(profile: profile, axis: axisPath) {
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(revolution)
                        circle.removeFromParentNode()
                        self.freePaths.removeAll(where: { $0 === profile || $0 == circle })
                    }
                }
            }
        }
    }
}

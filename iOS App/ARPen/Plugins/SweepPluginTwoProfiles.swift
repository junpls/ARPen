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
            
            let center1 = profile1.getCenter()
            let center2 = profile2.getCenter()
            
            //let midpoint = (center1 + center2) / 2
            var normal1 = profile1.getPC1()
            var normal2 = profile2.getPC1()
            
            var points = [ARPPathNode(center1, cornerStyle: .sharp)]

            /// Always choose the normal which is pointing more in the direction of the respective other endpoint.
            /// This should be changed in favor of less of a mockup behaviour, e.g. taking into account the pen's orientation while drawing.
            if normal1.dot(vector: center2-center1) < 0 {
                normal1 *= -1
            }
            if normal2.dot(vector: center1-center2) < 0 {
                normal2 *= -1
            }
            
            /// Edge case 1: If the resulting normals are very similar, orient them upwards (slinky-behaviour).
            if normal1.dot(vector: normal2) > 0.9 && normal1.y < 0 {
                normal1 *= -1
                normal2 *= -1
            }
            
            let pathScale = center1.distance(vector: center2) / 4
            
            var midpoint1 = center1 + normal1*pathScale
            midpoint1 += (center2 - center1) * 0.1
            
            var midpoint2 = center2 + normal2*pathScale
            midpoint2 += (center1 - center2) * 0.1

            // Edge case 2: If both normals are almost aligned with the center line between the profiles, don't add additional points s.t. the spine is just a straight line.
            if !((center2 - center1).normalized().dot(vector: normal1) > 0.9 &&
                (center1 - center2).normalized().dot(vector: normal2) > 0.9) {
                points.append(ARPPathNode(midpoint1, cornerStyle: .round))
                points.append(ARPPathNode(midpoint2, cornerStyle: .round))
            }

            points.append(ARPPathNode(center2, cornerStyle: .sharp))
            
            let spine = ARPPath(points: points, closed: false)
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

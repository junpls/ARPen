//
//  LinePlugin.swift
//  ARPen
//
//  Created by Jan on 04.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class SweepPluginTwoProfiles: Plugin, UserStudyRecordPluginProtocol, UserStudyStatePluginProtocol {
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
    
    /// **** For user study ****
    var recordManager: UserStudyRecordManager!
    var stateManager: UserStudyStateManager!
    private var taskTimeLogger = TaskTimeLogger()
    /// ************************
    
    init() {
        curveDesigner = CurveDesigner()
        curveDesigner.didCompletePath = self.didCompletePath;
        
        /// **** For user study ****
        curveDesigner.didStartPath = { _ in self.taskTimeLogger.startUnlessRunning() }
        /// ************************
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentView = view
        self.currentScene = scene
        
        /// **** For user study ****
        self.taskTimeLogger.defaultDict = ["Model": stateManager.task ?? ""]
        self.freePaths.removeAll()
        /// ************************
    }
    
    func deactivatePlugin() {
        
    }
    
    func injectUIButtons(_ buttons: [Button : UIButton]) {
        curveDesigner.injectUIButtons(buttons)
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
            let pc1 = profile1.getPC1()
            let pc2 = profile2.getPC1()
            
            var points = [ARPPathNode(center1, cornerStyle: .sharp)]
            
            var normal1: SCNVector3!
            var normal2: SCNVector3!
            var midpoint1: SCNVector3!
            var midpoint2: SCNVector3!

            let pathScale = center1.distance(vector: center2) / 4
            
            /// Find the slinky direction with the least amount of bending
            var minBending = Float.greatestFiniteMagnitude
            for d1 in [-1.0, 1.0] {
                for d2 in [-1.0, 1.0] {
                    
                    var n1 = pc1 * Float(d1)
                    var n2 = pc2 * Float(d2)
                    
                    /// Edge case 1: If the resulting normals are very similar, orient them upwards (slinky-behaviour).
                    if n1.dot(vector: n2) > 0.8 && n1.y < 0 {
                        n1 *= -1
                        n2 *= -1
                    }
                    
                    var mid1 = center1 + n1*pathScale
                    mid1 += (center2 - center1) * 0.1
                    
                    var mid2 = center2 + n2*pathScale
                    mid2 += (center1 - center2) * 0.1
                    
                    let m1toc1 = (center1 - mid1).normalized()
                    let m1tom2 = (mid2 - mid1).normalized()
                    let m2toc2 = (center2 - mid2).normalized()
                    let bending = m1toc1.dot(vector: m1tom2) + (m1tom2 * -1).dot(vector: m2toc2)
                    
                    if (bending < minBending) {
                        minBending = bending
                        midpoint1 = mid1
                        midpoint2 = mid2
                        normal1 = n1
                        normal2 = n2
                    }
                }
            }

            /// Edge case 2: If both normals are almost aligned with the center line between the profiles, don't add additional points s.t. the spine is just a straight line.
            if !((center2 - center1).normalized().dot(vector: normal1) > 0.8 &&
                (center1 - center2).normalized().dot(vector: normal2) > 0.8) {
                points.append(ARPPathNode(midpoint1, cornerStyle: .round))
                points.append(ARPPathNode(midpoint2, cornerStyle: .round))
            }

            points.append(ARPPathNode(center2, cornerStyle: .sharp))
            
            let spine = ARPPath(points: points, closed: false)
            self.currentScene?.drawingNode.addChildNode(spine)
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                /// **** For user study ****
                let targetMeasurementDict = self.taskTimeLogger.finish()
                self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: targetMeasurementDict)
                /// **** For user study ****
                
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

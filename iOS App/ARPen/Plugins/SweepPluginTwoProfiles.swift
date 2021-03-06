//
//  SweepPluginTwoProfiles.swift
//  ARPen
//
//  Created by Jan Benscheid on 04.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class SweepPluginTwoProfiles: Plugin, UIButtonPlugin, UserStudyRecordPluginProtocol, UserStudyStatePluginProtocol {
    
    var penButtons: [Button : UIButton]! {
        didSet {
            curveDesigner.injectUIButtons(self.penButtons)
        }
    }
    
    var undoButton: UIButton!
    
    var pluginImage: UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Sweep (Two Profiles)"
    var currentScene: PenScene?
    var currentView: ARSCNView?

    private var freePaths: [ARPPath] = [ARPPath]()
    private var busy: Bool = false
    
    private var curveDesigner: CurveDesigner
    
    // **** For user study ****
    var recordManager: UserStudyRecordManager!
    var stateManager: UserStudyStateManager!
    private var taskTimeLogger = TaskTimeLogger()
    private var taskCenter: SCNVector3 = SCNVector3(0, 0, 0.2)
    // ************************
    
    init() {
        curveDesigner = CurveDesigner()
        curveDesigner.didCompletePath = self.didCompletePath;
        
        // **** For user study ****
        curveDesigner.didStartPath = { _ in self.taskTimeLogger.startUnlessRunning() }
        // ************************
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentView = view
        self.currentScene = scene
        self.curveDesigner.reset()
        self.undoButton.addTarget(self, action: #selector(undo), for: .touchUpInside)

        // **** For user study ****
        self.taskTimeLogger.defaultDict = ["Model": stateManager.task ?? ""]
        self.taskTimeLogger.reset()
        self.freePaths.removeAll()
        TaskScenes.populateSceneBasedOnTask(scene: scene.drawingNode, task: stateManager.task ?? "", centeredAt: taskCenter)
        if let profile = scene.drawingNode.childNodes.first as? ARPPath {
            freePaths.append(profile)
        }
        // ************************
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
            
            // Find the slinky direction with the least amount of bending
            var minBending = Float.greatestFiniteMagnitude
            for d1 in [-1.0, 1.0] {
                for d2 in [-1.0, 1.0] {
                    
                    var n1 = pc1 * Float(d1)
                    var n2 = pc2 * Float(d2)
                    
                    // Edge case 1: If the resulting normals are very similar, orient them upwards (slinky-behaviour).
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

            // Edge case 2: If both normals are almost aligned with the center line between the profiles, don't add additional points s.t. the spine is just a straight line.
            if !((center2 - center1).normalized().dot(vector: normal1) > 0.8 &&
                (center1 - center2).normalized().dot(vector: normal2) > 0.8) {
                points.append(ARPPathNode(midpoint1, cornerStyle: .round))
                points.append(ARPPathNode(midpoint2, cornerStyle: .round))
            }

            points.append(ARPPathNode(center2, cornerStyle: .sharp))
            
            let spine = ARPPath(points: points, closed: false)
            self.currentScene?.drawingNode.addChildNode(spine)
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                // **** For user study ****
                self.taskTimeLogger.pause()
                // ************************
                
                if let sweep = try? ARPSweep(profile: profile1, path: spine) {
                    
                    // **** For user study ****
                    var targetMeasurementDict = self.taskTimeLogger.finish()
                    
                    switch self.stateManager.task {
                    case "Cube":
                        let cubeHeight = TaskScenes.cubeSize * TaskScenes.cubeScale
                        let deviation = TaskScenes.calcExtrusionDeviation(profile: profile1, spine: spine, targetHeight: cubeHeight)
                        targetMeasurementDict["Deviation"] = String(deviation)
                    case "Phone stand":
                        let phoneStandHeight = TaskScenes.phoneStandHeight * TaskScenes.phoneStandScale
                        let deviation = TaskScenes.calcExtrusionDeviation(profile: profile1, spine: spine, targetHeight: phoneStandHeight)
                        targetMeasurementDict["Deviation"] = String(deviation)
                    case "Handle":
                        let handleWidth = TaskScenes.handleWidth * TaskScenes.handleScale
                        let target = spine.points.first!.worldPosition + SCNVector3(handleWidth, 0, 0)
                        let actual = spine.points.last!.worldPosition
                        let deviation = target.distance(vector: actual) / handleWidth
                        targetMeasurementDict["Deviation"] = String(deviation)
                    default:
                        break
                    }

                    self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: targetMeasurementDict)
                    self.recordManager.saveStl(node: sweep, name: "SweepTwoProfiles_\(self.stateManager.task ?? "")")
                    // ************************

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

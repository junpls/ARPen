//
//  RevolvePluginTwoProfiles.swift
//  ARPen
//
//  Created by Jan Benscheid on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class RevolvePluginTwoProfiles: Plugin, UIButtonPlugin, UserStudyRecordPluginProtocol, UserStudyStatePluginProtocol {
    
    var penButtons: [Button : UIButton]! {
        didSet {
            curveDesigner.injectUIButtons(self.penButtons)
        }
    }
    
    var undoButton: UIButton!
    
    var pluginImage: UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Revolve (Two Profiles)"
    var currentScene: PenScene?
    var currentView: ARSCNView?
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    
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
        curveDesigner.didCompletePath = self.didCompletePath
        
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
        if let profile1 = freePaths.first(where: { !$0.closed && $0.points.count >= 2 }),
           let profile2 = freePaths.last(where: { !$0.closed && $0.points.count >= 2 }),
            profile1 !== profile2 {
            
            DispatchQueue.global(qos: .userInitiated).async {
                profile1.flatten()
                profile2.flatten()
                
                let profile1Start = profile1.points.first!.worldPosition
                let profile1End = profile1.points.last!.worldPosition
                let profile2Start = profile2.points.first!.worldPosition
                let profile2End = profile2.points.last!.worldPosition
                
                // The following lines determine which start- and endpoints of the profiles belong to each other, in case one profile was drawn e.g. top to bottom, and the other bottom to top.
                let centerStart, centerEnd: SCNVector3!
                let distanceParallel = profile1Start.distance(vector: profile2Start) + profile1End.distance(vector: profile2End)
                let distanceCross = profile1Start.distance(vector: profile2End) + profile1End.distance(vector: profile2Start)
                
                if distanceParallel < distanceCross {
                    centerStart = (profile1Start + profile2Start) / 2
                    centerEnd = (profile1End + profile2End) / 2
                } else {
                    centerStart = (profile1Start + profile2End) / 2
                    centerEnd = (profile1End + profile2Start) / 2
                }

                let axisPath = ARPPath(points: [
                    ARPPathNode(centerStart),
                    ARPPathNode(centerEnd)
                    ], closed: false);
                
                
                // **** For user study ****
                self.taskTimeLogger.pause()
                // ************************
                
                if let revolution = try? ARPRevolution(profile: profile1, axis: axisPath) {
                    
                    // **** For user study ****
                    var targetMeasurementDict = self.taskTimeLogger.finish()
                    
                    var targetRadiusTop, targetRadiusBottom: Float!

                    switch self.stateManager.task {
                    case "Door stopper":
                        targetRadiusTop = TaskScenes.doorStopperRadiusTop * TaskScenes.doorStopperScale
                        targetRadiusBottom = TaskScenes.doorStopperRadiusBottom * TaskScenes.doorStopperScale
                    case "Flower pot":
                        targetRadiusTop = TaskScenes.flowerPotRadiusTop * TaskScenes.flowerPotScale
                        targetRadiusBottom = TaskScenes.flowerPotRadiusBottom * TaskScenes.flowerPotScale
                    default:
                        break
                    }
                    
                    if ["Door stopper", "Flower pot"].contains(self.stateManager.task) {
                        let deviationTop = abs(revolution.radiusTop - targetRadiusTop)
                        let deviationBottom = abs(revolution.radiusBottom - targetRadiusBottom)
                        let deviation = (deviationTop + deviationBottom) / (targetRadiusTop + targetRadiusBottom)
                        targetMeasurementDict["DeviationRadius"] = String(deviation)
                        targetMeasurementDict["DeviationAngle"] = String(revolution.angle)
                    }
                    
                    self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: targetMeasurementDict)
                    self.recordManager.saveStl(node: revolution, name: "RevolveTwoProfiles_\(self.stateManager.task ?? "")")
                    // ************************
                    
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(revolution)
                        profile2.removeFromParentNode()
                        self.freePaths.removeAll(where: { $0 === profile1 || $0 == profile2 })
                    }
                }
            }
        }
    }
}

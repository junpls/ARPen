//
//  RevolvePlugin.swift
//  ARPen
//
//  Created by Jan on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class RevolvePluginProfileAndAxis: Plugin, UIButtonPlugin, UserStudyRecordPluginProtocol, UserStudyStatePluginProtocol {
    
    var penButtons: [Button : UIButton]! {
        didSet {
            curveDesigner.injectUIButtons(self.penButtons)
        }
    }
    
    var undoButton: UIButton!
    
    var pluginImage: UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Revolve (Profile + Axis)"
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
        curveDesigner.didCompletePath = self.didCompletePath
        
        /// **** For user study ****
        curveDesigner.didStartPath = { _ in self.taskTimeLogger.startUnlessRunning() }
        /// ************************
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentView = view
        self.currentScene = scene
        self.undoButton.addTarget(self, action: #selector(undo), for: .touchUpInside)

        /// **** For user study ****
        self.taskTimeLogger.defaultDict = ["Model": stateManager.task ?? ""]
        self.taskTimeLogger.reset()
        self.freePaths.removeAll()
        TaskScenes.populateSceneBasedOnTask(scene: scene.drawingNode, task: stateManager.task ?? "", centeredAt: SCNVector3(0, 0, 0))
        if let profile = scene.drawingNode.childNodes.first as? ARPPath {
            freePaths.append(profile)
        }
        /// ************************
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
        if let profile = freePaths.first(where: { !$0.closed && $0.points.count > 2 }),
            let axisPath = freePaths.first(where: { !$0.closed && $0.points.count == 2 }) {
                        
            DispatchQueue.global(qos: .userInitiated).async {
                profile.flatten()
                
                /// **** For user study ****
                self.taskTimeLogger.pause()
                /// ************************
                
                if let revolution = try? ARPRevolution(profile: profile, axis: axisPath) {
                    
                    /// **** For user study ****
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
                    /// ************************

                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(revolution)
                        self.freePaths.removeAll(where: { $0 === profile || $0 === axisPath })
                    }
                }
            }
        }
    }
}

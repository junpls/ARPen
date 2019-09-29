//
//  SweepPluginProfileAndPath.swift
//  ARPen
//
//  Created by Jan Benscheid on 04.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class SweepPluginProfileAndPath: Plugin, UIButtonPlugin, UserStudyRecordPluginProtocol, UserStudyStatePluginProtocol {
    
    var penButtons: [Button : UIButton]! {
        didSet {
            curveDesigner.injectUIButtons(self.penButtons)
        }
    }
    
    var undoButton: UIButton!
    
    var pluginImage: UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Sweep (Profile + Path)"
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
        if let profile = freePaths.first(where: { $0.closed }),
            let spine = freePaths.first(where: { !$0.closed && $0.points.count > 1 }) {
            DispatchQueue.global(qos: .userInitiated).async {
                profile.flatten()
                
                // **** For user study ****
                self.taskTimeLogger.pause()
                // ************************
                
                if let sweep = try? ARPSweep(profile: profile, path: spine) {
                    
                    // **** For user study ****
                    var targetMeasurementDict = self.taskTimeLogger.finish()
                    
                    switch self.stateManager.task {
                    case "Cube":
                        let cubeHeight = TaskScenes.cubeSize * TaskScenes.cubeScale
                        let deviation = TaskScenes.calcExtrusionDeviation(profile: profile, spine: spine, targetHeight: cubeHeight)
                        targetMeasurementDict["Deviation"] = String(deviation)
                    case "Phone stand":
                        let phoneStandHeight = TaskScenes.phoneStandHeight * TaskScenes.phoneStandScale
                        let deviation = TaskScenes.calcExtrusionDeviation(profile: profile, spine: spine, targetHeight: phoneStandHeight)
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
                    self.recordManager.saveStl(node: sweep, name: "SweepProfileAndPath_\(self.stateManager.task ?? "")")
                    // ************************
                    
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(sweep)
                        self.freePaths.removeAll(where: { $0 === profile || $0 === spine })
                    }
                }
            }
        }
    }
}

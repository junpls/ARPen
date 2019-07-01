//
//  RevolvePlugin.swift
//  ARPen
//
//  Created by Jan on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class RevolvePluginProfileAndCircle: Plugin, UIButtonPlugin, UserStudyRecordPluginProtocol, UserStudyStatePluginProtocol {
    
    var penButtons: [Button : UIButton]! {
        didSet {
            curveDesigner.injectUIButtons(self.penButtons)
        }
    }
    
    var undoButton: UIButton!
    
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
                
                /// **** For user study ****
                self.taskTimeLogger.pause()
                /// ************************
                
                if let revolution = try? ARPRevolution(profile: profile, axis: axisPath) {
                    
                    /// **** For user study ****
                    let targetMeasurementDict = self.taskTimeLogger.finish()
                    self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: targetMeasurementDict)
                    /// ************************
                    
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

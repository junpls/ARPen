//
//  LinePlugin.swift
//  ARPen
//
//  Created by Jan on 04.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class SweepPluginProfileAndPath: Plugin, UserStudyRecordPluginProtocol, UserStudyStatePluginProtocol {
    
    var pluginImage: UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Sweep (Profile + Path)"
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
        if let profile = freePaths.first(where: { $0.closed }),
            let spine = freePaths.first(where: { !$0.closed && $0.points.count > 1 }) {
            DispatchQueue.global(qos: .userInitiated).async {
                profile.flatten()
                
                /// **** For user study ****
                self.taskTimeLogger.pause()
                /// ************************
                
                if let sweep = try? ARPSweep(profile: profile, path: spine) {
                    
                    /// **** For user study ****
                    let targetMeasurementDict = self.taskTimeLogger.finish()
                    self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: targetMeasurementDict)
                    /// ************************
                    
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(sweep)
                        self.freePaths.removeAll(where: { $0 === profile || $0 === spine })
                    }
                }
            }
        }
    }
}

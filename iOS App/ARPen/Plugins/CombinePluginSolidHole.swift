//
//  ArrangePlugin.swift
//  ARPen
//
//  Created by Jan on 19.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//
import ARKit

class CombinePluginSolidHole: Plugin, UIButtonPlugin, UserStudyRecordPluginProtocol, UserStudyStatePluginProtocol {
    
    var penButtons: [Button : UIButton]! {
        didSet {
            self.penButtons[.Button1]?.setTitle("Select/Move", for: .normal)
            self.penButtons[.Button2]?.setTitle("Solid ↔ Hole", for: .normal)
            self.penButtons[.Button3]?.setTitle("Combine", for: .normal)
        }
    }
    
    var undoButton: UIButton!

    var pluginImage : UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Combine (Solid + Hole)"
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    
    private var buttonEvents: ButtonEvents
    private var arranger: Arranger
    
    /// **** For user study ****
    var recordManager: UserStudyRecordManager!
    var stateManager: UserStudyStateManager!
    private var taskTimeLogger = TaskTimeLogger()
    /// ************************
    
    init() {
        arranger = Arranger()
        buttonEvents = ButtonEvents()
        buttonEvents.didPressButton = self.didPressButton
        buttonEvents.didReleaseButton = self.didReleaseButton
        buttonEvents.didDoubleClick = self.didDoubleClick
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentView = view
        self.currentScene = scene
        self.arranger.activate(withScene: scene, andView: view)
        
        /// **** For user study ****
        self.taskTimeLogger.defaultDict = ["Model": stateManager.task ?? ""]
        self.taskTimeLogger.reset()
        TaskScenes.populateSceneBasedOnTask(scene: scene.drawingNode, task: stateManager.task ?? "", centeredAt: SCNVector3(0, 0, 0))
        /// ************************
    }
    
    func deactivatePlugin() {
        arranger.deactivate()
    }
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        arranger.update(scene: scene, buttons: buttons)
    }
    
    func didPressButton(_ button: Button) {
        
        /// **** For user study ****
        self.taskTimeLogger.startUnlessRunning()
        /// ************************
        
        switch button {
        case .Button1:
            break
        case .Button2:
            for case let target as ARPGeomNode in arranger.selectedTargets {
                target.isHole = !target.isHole
            }
            if case let target as ARPGeomNode = arranger.hoverTarget, !arranger.selectedTargets.contains(target) {
                target.isHole = !target.isHole
            }
        case .Button3:
            if arranger.selectedTargets.count == 2 {
                guard let a = arranger.selectedTargets.removeFirst() as? ARPGeomNode,
                   let b = arranger.selectedTargets.removeFirst() as? ARPGeomNode else {
                        return
                }
                
                var target = a
                var tool = b
                var createHole = false
                var operation: BooleanOperation!
                if a.isHole == b.isHole {
                    operation = .join
                    if a.isHole {
                        /// Hole + hole = join, but new object is a hole
                        createHole = true
                    }
                } else {
                    operation = .cut
                    target = b.isHole ? a : b
                    tool = b.isHole ? b : a
                }
                
                /// **** For user study ****
                self.taskTimeLogger.pause()
                /// ************************
                
                DispatchQueue.global(qos: .userInitiated).async {
                    if let res = try? ARPBoolNode(a: target, b: tool, operation: operation) {
                        
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(res)
                            res.isHole = createHole
                            
                            /// **** For user study ****
                            if TaskScenes.isTaskDone(scene: self.currentScene?.drawingNode, task: self.stateManager.task) {
                                let targetMeasurementDict = self.taskTimeLogger.finish()
                                self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: targetMeasurementDict)
                            }
                            /// **** For user study ****
                        }
                    }
                }
            }
        }
    }
    
    func didReleaseButton(_ button: Button) {
        
    }
    
    func didDoubleClick(_ button: Button) {
        
    }
    
}

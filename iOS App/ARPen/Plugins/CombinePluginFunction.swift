//
//  CombinePluginFunction.swift
//  ARPen
//
//  Created by Jan Benscheid on 19.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//
import ARKit

class CombinePluginFunction: Plugin, UIButtonPlugin, UserStudyRecordPluginProtocol, UserStudyStatePluginProtocol  {
    
    var penButtons: [Button : UIButton]! {
        didSet {
            self.penButtons[.Button1]?.setTitle("Select/Move", for: .normal)
            self.penButtons[.Button2]?.setTitle("Merge", for: .normal)
            self.penButtons[.Button3]?.setTitle("Cut", for: .normal)
        }
    }
    
    var undoButton: UIButton!
    
    var pluginImage : UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Combine (Function)"
    
    var currentScene: PenScene?
    var currentView: ARSCNView?

    private var buttonEvents: ButtonEvents
    private var arranger: Arranger
    
    // **** For user study ****
    var recordManager: UserStudyRecordManager!
    var stateManager: UserStudyStateManager!
    private var taskTimeLogger = TaskTimeLogger()
    private var taskCenter: SCNVector3 = SCNVector3(0, 0, 0.2)
    // ************************

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
        
        // **** For user study ****
        self.taskTimeLogger.defaultDict = ["Model": stateManager.task ?? ""]
        self.taskTimeLogger.reset()
        TaskScenes.populateSceneBasedOnTask(scene: scene.drawingNode, task: stateManager.task ?? "", centeredAt: taskCenter)
        // ************************
    }
    
    func deactivatePlugin() {
        arranger.deactivate()
    }
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        arranger.update(scene: scene, buttons: buttons)
    }
    
    func didPressButton(_ button: Button) {
        
        // **** For user study ****
        self.taskTimeLogger.startUnlessRunning()
        // ************************

        switch button {
        case .Button1:
            break
        case .Button2, .Button3:
            if arranger.selectedTargets.count == 2 {
                guard let b = arranger.selectedTargets.removeFirst() as? ARPGeomNode,
                    let a = arranger.selectedTargets.removeFirst() as? ARPGeomNode else {
                        return
                }
                
                // **** For user study ****
                self.taskTimeLogger.pause()
                // ************************
                
                DispatchQueue.global(qos: .userInitiated).async {
                    if let diff = try? ARPBoolNode(a: a, b: b, operation: button == .Button2 ? .join : .cut) {
                        
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(diff)
                            
                            // **** For user study ****
                            if TaskScenes.isTaskDone(scene: self.currentScene?.drawingNode, task: self.stateManager.task) {
                                let targetMeasurementDict = self.taskTimeLogger.finish()
                                self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: targetMeasurementDict)
                                self.recordManager.saveStl(node: diff, name: "CombineFunction_\(self.stateManager.task ?? "")")
                            }
                            // ************************
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

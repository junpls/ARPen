//
//  ArrangePlugin.swift
//  ARPen
//
//  Created by Jan on 19.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//
import ARKit

class ArrangePluginFunction: Plugin {
    
    var pluginImage : UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Arrange (Function)"
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */

    private var buttonEvents: ButtonEvents
    private var arranger: Arranger
    private var uiButtons: [Button:UIButton]?

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
    }
    
    func deactivatePlugin() {
        arranger.deactivate()
    }
    
    func injectUIButtons(_ buttons: [Button : UIButton]) {
        self.uiButtons = buttons
        buttons[.Button1]?.setTitle("Select/Move", for: .normal)
        buttons[.Button2]?.setTitle("Merge", for: .normal)
        buttons[.Button3]?.setTitle("Cut", for: .normal)
    }
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        arranger.update(scene: scene, buttons: buttons)
    }
    
    func didPressButton(_ button: Button) {

        switch button {
        case .Button1:
            break
        case .Button2, .Button3:
            if arranger.selectedTargets.count == 2 {
                let a = arranger.selectedTargets.removeFirst()
                let b = arranger.selectedTargets.removeFirst()
                
                DispatchQueue.global(qos: .userInitiated).async {
                    if let diff = try? ARPBoolNode(a: a, b: b, operation: button == .Button2 ? .join : .cut) {
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(diff)
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

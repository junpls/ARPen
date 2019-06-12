//
//  ArrangePlugin.swift
//  ARPen
//
//  Created by Jan on 19.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//
import ARKit

class ArrangePluginSolidHole: Plugin {
    
    var pluginImage : UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Arrange (Solid + Hole)"
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    
    private var buttonEvents: ButtonEvents
    private var arranger: Arranger
    
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
        buttons[.Button1]?.setTitle("Select/Move", for: .normal)
        buttons[.Button2]?.setTitle("Solid ↔ Hole", for: .normal)
        buttons[.Button3]?.setTitle("Combine", for: .normal)
    }
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        arranger.update(scene: scene, buttons: buttons)
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        case .Button1:
            break
        case .Button2:
            for target in arranger.selectedTargets {
                target.isHole = !target.isHole
            }
            if let target = arranger.hoverTarget, !arranger.selectedTargets.contains(target) {
                target.isHole = !target.isHole
            }
        case .Button3:
            if arranger.selectedTargets.count == 2 {
                let a = arranger.selectedTargets.removeFirst()
                let b = arranger.selectedTargets.removeFirst()
                
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
                
                DispatchQueue.global(qos: .userInitiated).async {
                    if let res = try? ARPBoolNode(a: target, b: tool, operation: operation) {
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(res)
                            res.isHole = createHole
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

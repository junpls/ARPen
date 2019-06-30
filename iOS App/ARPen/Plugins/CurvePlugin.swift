//
//  CurvePlugin.swift
//  ARPen
//
//  Created by Jan on 30.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class CurvePlugin: Plugin, UIButtonPlugin {
    
    var penButtons: [Button : UIButton]! {
        didSet {
            curveDesigner.injectUIButtons(self.penButtons)
        }
    }
    
    var undoButton: UIButton!
    
    var pluginImage: UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Paint Curves"
    var currentScene: PenScene?
    var currentView: ARSCNView?
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    
    private var curveDesigner: CurveDesigner
    init() {
        curveDesigner = CurveDesigner()
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.undoButton.addTarget(self, action: #selector(undo), for: .touchUpInside)
    }
    
    
    func deactivatePlugin() {
        
    }
    
    @objc func undo() {
        curveDesigner.undo()
    }
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        curveDesigner.update(scene: scene, buttons: buttons)
    }

}

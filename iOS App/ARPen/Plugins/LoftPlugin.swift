//
//  LoftPlugin.swift
//  ARPen
//
//  Created by Jan Benscheid on 16.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class LoftPlugin: Plugin, UIButtonPlugin {
    
    var penButtons: [Button : UIButton]! {
        didSet {
            curveDesigner.injectUIButtons(self.penButtons)
        }
    }
    
    var undoButton: UIButton!
    
    var pluginImage: UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Loft"
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    
    private var freePaths: [ARPPath] = [ARPPath]()
    private var loft: ARPLoft?
    private var busy: Bool = false
    
    private var curveDesigner: CurveDesigner
    
    init() {
        curveDesigner = CurveDesigner()
        curveDesigner.didCompletePath = self.didCompletePath;
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentView = view
        self.currentScene = scene
        self.undoButton.addTarget(self, action: #selector(undo), for: .touchUpInside)

        self.freePaths.removeAll()
        self.loft = nil
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
        
        if !(path.closed || path.points.count == 1) {
            return
        }
        
        path.flatten()
        freePaths.append(path)
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let l = self.loft {
                l.addProfile(path)
                self.freePaths.removeAll(where: { $0 === path })
            } else {
                if self.freePaths.count >= 2 {
                    let paths = [self.freePaths.removeFirst(), self.freePaths.removeFirst()]
                    if let l = try? ARPLoft(profiles: paths) {
                        self.loft = l
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(l)
                        }
                    }
                }
            }
        }
    }
}

//
//  LoftPlugin.swift
//  ARPen
//
//  Created by Jan on 16.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class LoftPlugin: Plugin {
    
    var pluginImage: UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Loft"
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    
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
    }
    
    func deactivatePlugin() {
        
    }
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        curveDesigner.update(scene: scene, buttons: buttons)
    }
    
    func didCompletePath(_ path: ARPPath) {
        
        if !(path.closed || path.points.count == 1) {
            return
        }
        
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

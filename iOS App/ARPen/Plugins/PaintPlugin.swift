//
//  PaintPlugin.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class PaintPlugin: Plugin {
    
    var pluginImage : UIImage? = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Paint"
    var currentScene : PenScene?
    var currentView: ARSCNView?
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    private var previousPoint: SCNVector3?
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        guard scene.markerFound else {
            //Don't reset the previous point to avoid disconnected lines if the marker detection failed for some frames
            //self.previousPoint = nil
            return
        }
        let pressed = buttons[Button.Button1]!
        
        if pressed, let previousPoint = self.previousPoint {
            let cylinderNode = SCNNode()
            cylinderNode.buildLineInTwoPointsWithRotation(from: previousPoint, to: scene.pencilPoint.position, radius: 0.001, color: UIColor.red)
            cylinderNode.name = "cylinderLine"
            scene.drawingNode.addChildNode(cylinderNode)
        }
        
        let pressed2 = buttons[Button.Button2]!
        if pressed2 {
            guard let boxNode = scene.drawingNode.childNode(withName: "BoxNode", recursively: false) else {
                var boxNode = SCNNode()
                boxNode = SCNNode.init(geometry: SCNBox.init(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0.0))
                boxNode.name = "BoxNode"
                boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                boxNode.position = scene.pencilPoint.position
                scene.drawingNode.addChildNode(boxNode)
                return
            }
            boxNode.position = scene.pencilPoint.position
            
        }
        
        self.previousPoint = scene.pencilPoint.position
        
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentScene = scene
        self.currentView = view
    }
    
    func deactivatePlugin() {
        self.currentScene = nil
        self.currentView = nil
    }
    
}

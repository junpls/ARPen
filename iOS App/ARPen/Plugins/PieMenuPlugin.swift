//
//  PieMenuPlugin.swift
//  ARPen
//
//  Created by Oliver Nowak on 14.11.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

class PieMenuPlugin: Plugin, PenDelegate, PenTrackingDelegate {
    
    var pluginImage: UIImage? = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "PieMenu"
    var scene: PenScene
    
    init(scene: PenScene) {
        self.scene = scene
    }
    
    func onIdleMovement(to position: SCNVector3) {
        //print("Idle movement to \(position)")
    }
    
    func onPenClickStarted(at position: SCNVector3, startedButton: Button) {
        print("Click started at \(position) for \(startedButton)")
    }
    
    func onPenMoved(to position: SCNVector3, clickedButtons: [Button]) {
        print("Moved to \(position) for \(clickedButtons)")
    }
    
    func onPenClickEnded(at position: SCNVector3, releasedButton: Button) {
        let path = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius: 0.05, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        let geometry = SCNShape(path: path, extrusionDepth: 0.01)
        
        geometry.firstMaterial?.diffuse.contents = UIColor.blue
        
        let node = SCNNode(geometry: geometry)
        //node.rotation = SCNVector4(90, 0, 0, 1)
        node.position = position
        scene.drawingNode.addChildNode(node)
        
        
    }
    
    func onAllMarkerLost() {
        scene.hiddenTip = true
    }
    
    func onFoundMarker() {
        scene.hiddenTip = false
    }

    
    
}

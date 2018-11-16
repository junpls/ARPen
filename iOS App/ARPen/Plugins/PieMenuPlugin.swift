//
//  PieMenuPlugin.swift
//  ARPen
//
//  Created by Oliver Nowak on 14.11.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import SpriteKit

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
    var itemNumber = 0
    func onPenClickEnded(at position: SCNVector3, releasedButton: Button) {
        //let geometry = SCNShape(path: drawMenu(item: itemNumber, itemCount: 7, itemDistance: 5.degreesToRadians, innerRadius: 0.01, outerRadius: 0.05), extrusionDepth: 0.005)
        
        //geometry.firstMaterial?.diffuse.contents = UIColor.blue
            let node = drawMenu(item: itemNumber, itemCount: 8, itemDistance: 10, innerRadius: 0.01, outerRadius:   0.05)//SCNNode(geometry: geometry)
            node.position = scene.pencilPoint.position
            scene.drawingNode.addChildNode(node)
        itemNumber = (itemNumber + 1) % 8
        
        
    }
    
    func onAllMarkerLost() {
        scene.hiddenTip = true
    }
    
    func onFoundMarker() {
        scene.hiddenTip = false
    }
    
    func drawMenu(item: Int, itemCount: Int, itemDistance: CGFloat, innerRadius: CGFloat, outerRadius: CGFloat) -> SCNNode {
        let normalizedInnerRadius: CGFloat = innerRadius * 10000
        let normalizedOuterRadius: CGFloat = outerRadius * 10000
        
        let itemAngle: CGFloat = 2 * CGFloat.pi / CGFloat(itemCount)
        
        let path = UIBezierPath()
        path.lineWidth = 1
        
        let startAngle = CGFloat(item) * itemAngle
        let endAngle = startAngle + itemAngle
        
        path.move(to: CGPoint.zero)
        path.addArc(withCenter: CGPoint.zero, radius: normalizedInnerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        path.addArc(withCenter: CGPoint.zero, radius: normalizedOuterRadius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
        path.close()

        
        let shape = SKShapeNode(path: path.cgPath)
        shape.fillColor = #colorLiteral(red: 0.2175237018, green: 0.5705535949, blue: 1, alpha: 0.8038622359)
        shape.strokeColor = UIColor.clear
        
        let skScene = SKScene(size: path.bounds.size)
        skScene.backgroundColor = #colorLiteral(red: 1, green: 0.9510218243, blue: 0, alpha: 0.8038622359)
        shape.position = CGPoint(x: -path.bounds.minX, y: -path.bounds.minY)
        
        skScene.addChild(shape)
        
        
        let plane = SCNPlane(width: skScene.size.width / 10000, height: skScene.size.height / 10000)
        let material = SCNMaterial()
        material.isDoubleSided = true
        material.diffuse.contents = skScene
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        return node
        
    }

    
    
}

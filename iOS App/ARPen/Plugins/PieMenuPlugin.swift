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
        let node = drawMenu(itemCount: 8, itemDistance: 0.001, innerRadius: 0.01, outerRadius:   0.05)//SCNNode(geometry: geometry)
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
    
    func drawMenu(itemCount: Int, itemDistance: CGFloat, innerRadius: CGFloat, outerRadius: CGFloat) -> SCNNode {
        let normalizedInnerRadius: CGFloat = innerRadius * 10000
        let normalizedOuterRadius: CGFloat = outerRadius * 10000
        let menuNode = SCNNode(geometry: SCNSphere(radius: 0.005))
        
        for item in 0 ..< itemCount {
            let itemAngle: CGFloat = 2 * CGFloat.pi / CGFloat(itemCount)
            
            let path = UIBezierPath()
            path.lineWidth = 1
            
            let startAngle = CGFloat(item) * itemAngle
            let endAngle = startAngle + itemAngle
            let innerSpaceAngle = innerRadius != 0 ? atan(itemDistance / 2 / innerRadius ) : 0
            let outerSpaceAngle = outerRadius != 0 ? atan(itemDistance / 2 / outerRadius) : 0
            let startingPoint = CGPoint(x: normalizedInnerRadius * cos(startAngle + innerSpaceAngle), y: normalizedInnerRadius * sin(startAngle + innerSpaceAngle))
            
            path.move(to: startingPoint)
            path.addArc(withCenter: CGPoint.zero, radius: normalizedInnerRadius, startAngle: startAngle + innerSpaceAngle, endAngle: endAngle - innerSpaceAngle, clockwise: true)
            path.addArc(withCenter: CGPoint.zero, radius: normalizedOuterRadius, startAngle: endAngle - outerSpaceAngle, endAngle: startAngle + outerSpaceAngle, clockwise: false)
            path.close()

            
            let shape = SKShapeNode(path: path.cgPath)
            shape.fillColor = UIColor(red: 0.218, green: 0.571, blue: 1, alpha: 0.8)
            shape.strokeColor = UIColor(red: 0.218, green: 0.571, blue: 1, alpha: 1)
            shape.lineWidth = 5
            
            let skScene = SKScene(size: path.bounds.size)
            skScene.backgroundColor = UIColor.clear
            shape.position = CGPoint(x: -path.bounds.minX, y: -path.bounds.minY)
            
            skScene.addChild(shape)
            
            let plane = SCNPlane(width: skScene.size.width / 10000, height: skScene.size.height / 10000)
            let material = SCNMaterial()
            material.isDoubleSided = true
            material.diffuse.contents = skScene
            plane.materials = [material]
            let node = SCNNode(geometry: plane)

            node.position.x = Float(0.5 * plane.width + plane.width * (path.bounds.minX / path.bounds.width))
            node.position.y = Float(-0.5 * plane.height - plane.height * (path.bounds.minY / path.bounds.height))
            
            menuNode.addChildNode(node)
        }
        return menuNode
        
    }

    
    
}

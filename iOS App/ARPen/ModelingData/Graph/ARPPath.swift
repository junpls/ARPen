//
//  ARPPath.swift
//  ARPen
//
//  Created by Jan on 25.03.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class ARPPath: ARPGeomNode {
    
    let color = UIColor.red
    
    var points:[SCNNode] = [SCNNode]()
    var closed:Bool = false
    
    init(points:[SCNVector3], closed:Bool) {
        self.closed = closed
        
        for point in points {
            let node = SCNNode()
            node.geometry = SCNSphere(radius: 0.002)
            node.geometry?.firstMaterial?.diffuse.contents = color
            node.geometry?.firstMaterial?.lightingModel = .constant
            node.position = point
            self.points.append(node)
        }

        super.init()
        
        for point in self.points {
            self.content.addChildNode(point)
        }
        
        self.lineColor = color
    }
    
    func appendPoint(_ point:SCNVector3) {
        let node = SCNNode()
        node.geometry = SCNSphere(radius: 0.002)
        node.geometry?.firstMaterial?.diffuse.contents = color
        node.geometry?.firstMaterial?.lightingModel = .constant
        node.position = point
        self.points.append(node)
        self.content.addChildNode(node)
    }
    
    func removeLastPoint() {
        let removed = self.points.removeLast()
        removed.removeFromParentNode()
    }
    
    func coincidentDimensions() -> Int {
        return OCCTAPI.shared.conincidentDimensions(getPointsAsVectors())
    }
    
    func flatten() {
        for (old, new) in zip(points, OCCTAPI.shared.flattened(getPointsAsVectors())) {
            old.position = new
        }
    }
    
    func getPointsAsVectors() -> [SCNVector3] {
        return points.map { $0.position }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        let positions = points.map { $0.position }
        return try OCCTAPI.shared.createPath(points: positions, closed: closed)
    }
}

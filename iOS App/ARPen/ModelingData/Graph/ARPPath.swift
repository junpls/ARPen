//
//  ARPPath.swift
//  ARPen
//
//  Created by Jan on 25.03.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class ARPPath: ARPGeomNode {
    
    var points:[SCNNode] = [SCNNode]()
    var closed:Bool = false
    
    init(points:[SCNVector3], closed:Bool) {
        self.closed = closed
        
        for point in points {
            let node = SCNNode()
            node.geometry = SCNSphere(radius: 0.005)
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            node.position = point
            self.points.append(node)
        }

        super.init()
        
        for point in self.points {
            self.addChildNode(point)
        }
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        let positions = points.map { $0.position }
        return try OCCTAPI.shared.createPath(points: positions, closed: closed)
    }
}

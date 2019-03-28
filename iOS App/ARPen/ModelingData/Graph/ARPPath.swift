//
//  ARPPath.swift
//  ARPen
//
//  Created by Jan on 25.03.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class ARPPath: ARPGeomNode {
    
    var points:[SCNVector3] = [SCNVector3]()
    var closed:Bool = false
    
    init(points:[SCNVector3], closed:Bool) {
        self.points = points
        self.closed = closed
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        return try OCCTAPI.shared.createPath(points: points, closed: closed)
    }
}

//
//  ARPPath.swift
//  ARPen
//
//  Created by Jan on 25.03.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

enum CornerStyle {
    case sharp, round
}

class ARPPathNode: ARPNode {
    
    let sharpColor = UIColor.red
    let roundColor = UIColor.blue

    var cornerStyle = CornerStyle.sharp {
        didSet {
            updateCornerStyle()
        }
    }
    
    convenience init(_ x: Float, _ y: Float, _ z: Float, cornerStyle: CornerStyle = CornerStyle.sharp) {
        self.init(SCNVector3(x, y, z), cornerStyle: cornerStyle)
    }
    
    init(_ position: SCNVector3, cornerStyle: CornerStyle = CornerStyle.sharp) {
        super.init()
        self.geometry = SCNSphere(radius: 0.002)
        self.geometry?.firstMaterial?.lightingModel = .constant
        self.cornerStyle = cornerStyle
        updateCornerStyle()
        self.position = position
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateCornerStyle() {
        self.geometry?.firstMaterial?.diffuse.contents = self.cornerStyle == .sharp ? sharpColor : roundColor
    }
}

class ARPPath: ARPGeomNode {
    
    let color = UIColor.red
    
    var points:[ARPPathNode] = [ARPPathNode]()
    var closed:Bool = false
    
    init(points:[ARPPathNode], closed:Bool) {
        self.closed = closed
        
        for point in points {
            self.points.append(point)
        }

        super.init()
        
        for point in self.points {
            self.content.addChildNode(point)
        }
        
        self.lineColor = color
    }
    
    func appendPoint(_ point:ARPPathNode) {
        self.points.append(point)
        self.content.addChildNode(point)
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

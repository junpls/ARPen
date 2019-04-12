//
//  ARPPath.swift
//  ARPen
//
//  Created by Jan on 25.03.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

enum CornerStyle: Int32 {
    case sharp = 1, round = 2
}

class ARPPathNode: ARPNode {
    
    let sharpColor = UIColor.red
    let roundColor = UIColor.blue

    var cornerStyle = CornerStyle.sharp {
        didSet {
            updateCornerStyle()
        }
    }
    
    var fixed = false
    
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
    
    func removeNonFixedPoints() {
        points.removeAll(where: { !$0.fixed })
    }
    
    func getNonFixedPoint() -> ARPPathNode? {
        return points.last(where: { !$0.fixed })
    }
    
    func getPointsAsVectors() -> [SCNVector3] {
        return points.map { $0.position }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        let positions = points.compactMap { (!closed || $0.fixed) ? $0.position : nil }
        let corners = points.compactMap { (!closed || $0.fixed) ? $0.cornerStyle : nil }
        print(positions.count)
        return try OCCTAPI.shared.createPath(points: positions, corners: corners, closed: closed)
    }
}

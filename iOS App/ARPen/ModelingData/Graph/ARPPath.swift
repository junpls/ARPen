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
    /*
    static let highlightAnimation = SCNAction.customAction(duration: 2*Double.pi, action: { (node, elapsedTime) in
        let rgb = (sin(elapsedTime*2)+1) / 2
        let color = UIColor(red: rgb, green: rgb, blue: rgb, alpha: 1)
        node.geometryNode.geometry?.firstMaterial?.emission.contents = color
    })*/
    
    static let samePointTolerance: Float = 0.001

    static let radius: CGFloat = 0.002

    static let highlightScale: Float = 2
    static let highlightColor: UIColor = UIColor.white

    let sharpColor = UIColor.red
    let roundColor = UIColor.blue

    let geometryNode: SCNNode = SCNNode()
    
    var cornerStyle = CornerStyle.sharp {
        didSet {
            updateCornerStyle()
        }
    }
    
    var fixed = false {
        didSet {
            updateFixedState()
        }
    }
    
    convenience init(_ x: Float, _ y: Float, _ z: Float, cornerStyle: CornerStyle = CornerStyle.sharp) {
        self.init(SCNVector3(x, y, z), cornerStyle: cornerStyle)
    }
    
    init(_ position: SCNVector3, cornerStyle: CornerStyle = CornerStyle.sharp) {
        super.init()
        self.addChildNode(geometryNode)
        self.geometryNode.geometry = SCNSphere(radius: ARPPathNode.radius)
        self.geometryNode.geometry?.firstMaterial?.lightingModel = .constant
        self.geometryNode.geometry?.firstMaterial?.emission.contents = ARPPathNode.highlightColor
        self.geometryNode.geometry?.firstMaterial?.emission.intensity = 0
        self.cornerStyle = cornerStyle
        updateCornerStyle()
        updateFixedState()
        self.position = position
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func applyTransform() {
        (parent?.parent as? ARPGeomNode)?.rebuild()
    }
    
    func updateCornerStyle() {
        self.geometryNode.geometry?.firstMaterial?.diffuse.contents = self.cornerStyle == .sharp ? sharpColor : roundColor
    }
    
    func updateFixedState() {
        /// Wanted to highlight the non-fixed point to distinguish it. Just looked distracting though.
        /*
        if self.fixed {
            self.removeAction(forKey: "blinking")
            self.geometry?.firstMaterial?.emission.contents = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        } else {
            self.runAction(SCNAction.repeatForever(ARPPathNode.highlightAnimation), forKey: "blinking")
        }
        */
    }
    
    override func updateHighlightedState() {
        if highlighted {
            self.geometryNode.scale = SCNVector3(ARPPathNode.highlightScale, ARPPathNode.highlightScale, ARPPathNode.highlightScale)
        } else {
            self.geometryNode.scale = SCNVector3(1, 1, 1)
        }
    }
    
    override func updateSelectedState() {
        if selected {
            self.geometryNode.geometry?.firstMaterial?.emission.intensity = 1
        } else {
            self.geometryNode.geometry?.firstMaterial?.emission.intensity = 0
        }
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

        super.init(pivotChild: points[0])
        
        for point in self.points {
            self.content.addChildNode(point)
        }
        self.content.isHidden = false
        self.lineColor = color
    }
    
    func appendPoint(_ point:ARPPathNode, at position:Int = -1) {
        if position >= 0 {
            self.points.insert(point, at: position)
        } else {
            self.points.append(point)
        }
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
            old.worldPosition = new
        }
        self.rebuild()
    }
    
    func removeNonFixedPoints() {
        points.filter({ !$0.fixed }).forEach({ $0.removeFromParentNode() })
        points.removeAll(where: { !$0.fixed })
    }
    
    func getNonFixedPoint() -> ARPPathNode? {
        return points.last(where: { !$0.fixed })
    }
    
    func getPointsAsVectors() -> [SCNVector3] {
        return points.map { $0.worldPosition }
    }
    
    func getCenter() -> SCNVector3 {
        let sum = points.map { $0.worldPosition }.reduce(SCNVector3(0,0,0), { $0 + $1 })
        return sum / Float(points.count)
    }
    
    func getPC1() -> SCNVector3 {
        return OCCTAPI.shared.pc1(getPointsAsVectors())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateVisitedState() {}
    
    override func build() throws -> OCCTReference {
        var calcClosed = closed
        if let first = points.first, let last = points.last,
            first.position.distance(vector: last.position) < ARPPathNode.samePointTolerance {
            calcClosed = true
        }
        let positions = points.compactMap { (!calcClosed || $0.fixed) ? $0.worldPosition : nil }
        let corners = points.compactMap { (!calcClosed || $0.fixed) ? $0.cornerStyle : nil }
        
        let ref = try? OCCTAPI.shared.createPath(points: positions, corners: corners, closed: calcClosed)
        if let r = ref {
            OCCTAPI.shared.pivot(handle: r, pivot: pivotChild.worldTransform)
        }
        
        self.lineColor = calcClosed ? UIColor.green : UIColor.red

        return ref ?? ""
    }
}

//
//  File.swift
//  Loop
//
//  Created by Jan on 15.02.19.
//  Copyright © 2019 Jan. All rights reserved.
//

import Foundation

enum BooleanOperation {
    case join
    case cut
    case intersect
}

enum BooleanError: Error {
    case operationUnknown
}

class ARPBoolNode: ARPGeomNode {
    
    var a:ARPGeomNode
    var b:ARPGeomNode
    
    let operation:BooleanOperation
    
    init(a:ARPGeomNode, b:ARPGeomNode, operation op:BooleanOperation) throws {
        self.a = a
        self.b = b
        self.operation = op
        
        a.isHidden = true
        b.isHidden = true
        a.removeFromParentNode()
        b.removeFromParentNode()
        
        super.init()
        
        self.addChildNode(a)
        self.addChildNode(b)
        
        // build function moved the node. Apply change to OCCT and child nodes
        self.applyTransform_()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        let ref: OCCTReference?
        switch self.operation {
        case .cut:
            ref = try? OCCTAPI.shared.boolean(from: a.occtReference!, cut: b.occtReference!)
        case .join:
            ref = try? OCCTAPI.shared.boolean(join: a.occtReference!, with: b.occtReference!)
        case .intersect:
            ref = try? OCCTAPI.shared.boolean(intersect: a.occtReference!, with: b.occtReference!)
        }
        
        if let handle = ref {
            // Generated shape has its origin at 0,0,0. Shift it s.t. the new origin is in the center of its AABB.
            let center = OCCTAPI.shared.center(handle: handle)
            self.position = self.position + center
        }
        
        return ref ?? ""
    }
}

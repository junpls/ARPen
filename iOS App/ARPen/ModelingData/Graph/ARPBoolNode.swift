//
//  File.swift
//  Loop
//
//  Created by Jan on 15.02.19.
//  Copyright © 2019 Jan. All rights reserved.
//

import Foundation

enum BooleanOperation {
    case join, cut, intersect
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
        
        //a.removeFromParentNode()
        //b.removeFromParentNode()

        super.init(pivotChild: a)
        self.geometryColor = a.geometryColor

        a.isHidden = true
        b.isHidden = true
        self.content.addChildNode(a)
        self.content.addChildNode(b)
        
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
        
        if let r = ref {
            OCCTAPI.shared.pivot(handle: r, pivot: pivotChild.worldTransform)
        }
        
        return ref ?? ""
    }
}

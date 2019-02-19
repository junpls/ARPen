//
//  ARPGeomNode.swift
//  Loop
//
//  Created by Jan on 15.02.19.
//  Copyright © 2019 Jan. All rights reserved.
//

import Foundation

class ARPGeomNode: ARPNode {
    
    var occtReference:OCCTReference?
    
    var geometryNode: SCNNode = SCNNode()
    var isoLinesNode: SCNNode = SCNNode()
    
    override init() {
        super.init()
        self.addChildNode(geometryNode)
        self.addChildNode(isoLinesNode)
        self.occtReference = try? build()
        self.updateView()
    }

    final func updateView() {
        geometryNode.removeFromParentNode();
        let geom = OCCTAPI.shared.triangulate(handle: occtReference!)
        geometryNode = SCNNode(geometry: geom)
        self.addChildNode(geometryNode)
        /// This was necessary for world coordinates
        //geometryNode.setWorldTransform(SCNMatrix4(m11: 1, m12: 0, m13: 0, m14: 0, m21: 0, m22: 1, m23: 0, m24: 0, m31: 0, m32: 0, m33: 1, m34: 0, m41: 0, m42: 0, m43: 0, m44: 1))
    }
    
    /// Call to apply changes in translation, rotation or scale to OCCT.
    final func applyTransform() {
        self.applyTransform_()
        try? (parent as? ARPGeomNode)?.rebuild()
    }
    
    final func applyTransform_() {
        OCCTAPI.shared.transform(handle: occtReference!, transformation: self.transform)
        
        /// This was necessary for world coordinates
        // OCCTAPI.shared.transform(handle: occtReference!, transformation: self.worldTransform)
        /*
        for c in childNodes {
            if let geom = c as? ARPGeomNode {
                geom.applyTransform_()
            }
        }*/
    }
    
    func build() throws -> OCCTReference {
        fatalError("Must Override")
    }
    
    final func rebuild() throws {
        if let ref = occtReference {
            OCCTAPI.shared.free(handle: ref)
        }
        if let ref = try? build() {
            occtReference = ref
            applyTransform_()
            updateView()
            try? (parent as? ARPGeomNode)?.rebuild()
        } else {
            print("FAILED TO REBUILD")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        OCCTAPI.shared.free(handle: occtReference!)
    }
}

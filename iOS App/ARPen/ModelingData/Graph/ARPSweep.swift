//
//  ARPSweep.swift
//  ARPen
//
//  Created by Jan on 26.03.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//
import Foundation


class ARPSweep: ARPGeomNode {
    
    var profile:ARPPath
    var path:ARPPath

    init(profile:ARPPath, path:ARPPath) throws {
        self.profile = profile
        self.path = path
        
        profile.isHidden = true
        path.isHidden = true
        profile.removeFromParentNode()
        path.removeFromParentNode()
        
        super.init()
        
        self.addChildNode(profile)
        self.addChildNode(path)
        
        // build function moved the node. Apply change to OCCT and child nodes
        self.applyTransform_()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        let ref = try? OCCTAPI.shared.sweep(profile: profile.occtReference!, path: path.occtReference!)

        if let handle = ref {
            // Generated shape has its origin at 0,0,0. Shift it s.t. the new origin is in the center of its AABB.
            let center = OCCTAPI.shared.center(handle: handle)
            self.position = center//self.position + center
        }
        
        return ref ?? ""
    }
}

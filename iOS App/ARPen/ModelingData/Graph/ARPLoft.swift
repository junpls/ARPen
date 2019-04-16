//
//  ARPLoft.swift
//  ARPen
//
//  Created by Jan on 16.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class ARPLoft: ARPGeomNode {
    
    var profiles: [ARPPath]
    
    init(profiles: [ARPPath]) throws {
        
        self.profiles = profiles
        
        super.init(pivotChild: profiles[0])
        
        for profile in profiles {
            profile.isHidden = true
            self.content.addChildNode(profile)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addProfile(_ profile: ARPPath) {
        profiles.append(profile)
        content.addChildNode(profile)
        profile.isHidden = true
        rebuild()
    }
    
    override func build() throws -> OCCTReference {
        let ref = try? OCCTAPI.shared.loft(profiles: profiles.map({ $0.occtReference! }))
        
        if let r = ref {
            OCCTAPI.shared.pivot(handle: r, pivot: pivotChild.worldTransform)
        }
        
        return ref ?? ""
    }
}

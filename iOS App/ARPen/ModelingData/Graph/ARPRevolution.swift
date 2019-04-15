//
//  ARPRevolution.swift
//  ARPen
//
//  Created by Jan on 13.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation


class ARPRevolution: ARPGeomNode {
    
    var profile:ARPPath
    
    init(profile:ARPPath) throws {
        
        self.profile = profile
        
        super.init(pivotChild: profile)
        
        profile.isHidden = true
        self.content.addChildNode(profile)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        
        let axisDirection = profile.points.last!.position - profile.points.first!.position
        let com = profile.points.map({$0.position}).reduce(SCNVector3(), +) / Float(profile.points.count)
        let delta = (profile.points.first!.position - com).normalized()
        let axisPosition = profile.points.first!.position + delta*0.02
        
        let ref = try? OCCTAPI.shared.revolve(profile: profile.occtReference!, aroundAxis: axisPosition, withDirection: axisDirection)
        
        if let r = ref {
            OCCTAPI.shared.pivot(handle: r, pivot: pivotChild.worldTransform)
        }
        
        return ref ?? ""
    }
}

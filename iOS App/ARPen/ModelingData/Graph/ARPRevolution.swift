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
    var axis:Axis

    init(profile: ARPPath, axis: Axis) throws {
        
        self.profile = profile
        self.axis = axis
        
        super.init(pivotChild: profile)
        
        profile.isHidden = true
        self.content.addChildNode(profile)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        func projectToAxis(point: SCNVector3) -> SCNVector3 {
            return axis.position + axis.direction*(point - axis.position).dot(vector: axis.direction)
        }
        
        let closedProfile = ARPPath(points: profile.points, closed: true)
        let top = ARPPathNode(projectToAxis(point: profile.points.last!.position))
        top.fixed = true
        closedProfile.points.append(top)
        let bottom = ARPPathNode(projectToAxis(point: profile.points.first!.position))
        bottom.fixed = true
        closedProfile.points.insert(bottom, at: 0)
        closedProfile.flatten()
        closedProfile.rebuild()

        let ref = try? OCCTAPI.shared.revolve(profile: closedProfile.occtReference!, aroundAxis: axis.position, withDirection: axis.direction)
        
        if let r = ref {
            OCCTAPI.shared.pivot(handle: r, pivot: pivotChild.worldTransform)
        }
        
        return ref ?? ""
    }
}

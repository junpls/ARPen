//
//  OCCTAPI.swift
//  Loop
//
//  Created by Jan on 08.02.19.
//  Copyright © 2019 Jan. All rights reserved.
//

import Foundation
import SceneKit

typealias OCCTReference = String

enum OCCTError: Error {
    case couldNotCreateGeometry
}

class OCCTAPI {
    
    static let shared = OCCTAPI()
    
    let occt:OCCT = OCCT()
    
    func createSphere(radius:Double) throws -> OCCTReference {
        if let cString = occt.createSphere(radius) {
            let ref = OCCTReference(cString: cString)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func createBox(width:Double, height:Double, length:Double) throws -> OCCTReference {
        if let cString = occt.createBox(width, height: height, length: length) {
            let ref = OCCTReference(cString: cString)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func boolean(from a: OCCTReference, cut b: OCCTReference) throws -> OCCTReference {
        if let difference = occt.booleanCut(a, subtract: b) {
            let ref = OCCTReference(cString: difference)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func boolean(join a: OCCTReference, with b: OCCTReference) throws -> OCCTReference {
        if let sum = occt.booleanJoin(a, with: b) {
            let ref = OCCTReference(cString: sum)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func boolean(intersect a: OCCTReference, with b: OCCTReference) throws -> OCCTReference {
        if let sum = occt.booleanIntersect(a, with: b) {
            let ref = OCCTReference(cString: sum)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func transform(handle: OCCTReference, transformation: SCNMatrix4) {
        occt.setTransformOf(handle, transformation: transformation)
    }
    
    func center(handle: OCCTReference) -> SCNVector3 {
        return occt.center(handle);
    }
    
    
    func triangulate(handle: OCCTReference) -> SCNGeometry {
        return occt.sceneKitMesh(of: handle)
    }
    
    func wireframe(handle: OCCTReference) -> SCNGeometry {
        return occt.sceneKitLines(of: handle)
    }
    
    
    func free(handle: OCCTReference) {
        occt.freeShape(handle)
    }
}

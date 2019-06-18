//
//  CombinationDemoScenes.swift
//  ARPen
//
//  Created by Jan on 18.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class CombinationDemoScenes {
    
    static func populateSceneBasedOnTask(scene: SCNNode, task: String, centeredAt position: SCNVector3) {
        
        var objects = [ARPNode]()
        
        switch task {
        case "Candle holder":
            objects = CombinationDemoScenes.candleHolderScene(centeredAt: position)
        case "Spoon":
            objects = CombinationDemoScenes.spoonScene(centeredAt: position)
        case "Pen holder":
            objects = CombinationDemoScenes.penHolderScene(centeredAt: position)
        default:
            break
        }
        
        for obj in objects {
            scene.addChildNode(obj)
        }
    }
    
    static func isTaskDone(scene scn: SCNNode?, task tsk: String?) -> Bool {
        
        guard let scene = scn, let task = tsk else {
            return false
        }
        
        switch task {
        case "Candle holder":
            for case let node as ARPBoolNode in scene.childNodes {
                if node.name == "(cube-cylinder)" {
                    return true
                }
            }
            return false
        case "Spoon":
            for case let node as ARPBoolNode in scene.childNodes {
                if node.name == "((bigSphere-smallSphere)+cylinder)" ||
                    node.name == "((bigSphere+cylinder)-smallSphere)" {
                    return true
                }
            }
            return false
        case "Pen holder":
            for case let node as ARPBoolNode in scene.childNodes {
                if node.name == "(((smallCylinder-smallCylinderInner)+bigCylinder)-bigCylinderInner)" {
                    return true
                }
            }
            return false
        default:
            return false
        }
    }
    
    static func candleHolderScene(centeredAt positon: SCNVector3) -> [ARPNode] {
        let cube = ARPBox(width: 0.05, height: 0.05, length: 0.05)
        cube.position = positon + SCNVector3(-0.1, 0.025, 0)
        cube.applyTransform()
        cube.name = "cube"
        
        let cylinder = ARPCylinder(radius: 0.02, height: 0.025)
        cylinder.position = positon + SCNVector3(0.1, 0.0125, 0)
        cylinder.applyTransform()
        cylinder.name = "cylinder"
        
        return [cube, cylinder]
    }
    
    static func spoonScene(centeredAt positon: SCNVector3) -> [ARPNode] {
        let bigSphere = ARPSphere(radius: 0.02)
        bigSphere.position = positon + SCNVector3(-0.1, 0.02, 0)
        bigSphere.applyTransform()
        bigSphere.name = "bigSphere"
        
        let smallSphere = ARPSphere(radius: 0.0175)
        smallSphere.position = positon + SCNVector3(0, 0.0175, 0)
        smallSphere.applyTransform()
        smallSphere.name = "smallSphere"

        let cylinder = ARPCylinder(radius: 0.005, height: 0.07)
        cylinder.position = positon + SCNVector3(0.1, 0.005, 0)
        cylinder.rotation = SCNVector4(0, 0, 1, Float.pi/2)
        cylinder.applyTransform()
        cylinder.name = "cylinder"
        
        return [bigSphere, smallSphere, cylinder]
    }
    
    static func penHolderScene(centeredAt positon: SCNVector3) -> [ARPNode] {
        let bigCylinder = ARPCylinder(radius: 0.025, height: 0.08)
        bigCylinder.position = positon + SCNVector3(-0.2, 0.04, 0)
        bigCylinder.applyTransform()
        bigCylinder.name = "bigCylinder"
        
        let bigCylinderInner = ARPCylinder(radius: 0.02, height: 0.08)
        bigCylinderInner.position = positon + SCNVector3(-0.1, 0.04, 0)
        bigCylinderInner.applyTransform()
        bigCylinderInner.name = "bigCylinderInner"

        let smallCylinder = ARPCylinder(radius: 0.02, height: 0.06)
        smallCylinder.position = positon + SCNVector3(0.1, 0.03, 0)
        smallCylinder.applyTransform()
        smallCylinder.name = "smallCylinder"

        let smallCylinderInner = ARPCylinder(radius: 0.015, height: 0.06)
        smallCylinderInner.position = positon + SCNVector3(0.2, 0.03, 0)
        smallCylinderInner.applyTransform()
        smallCylinderInner.name = "smallCylinderInner"

        return [bigCylinder, bigCylinderInner, smallCylinder, smallCylinderInner]
    }
}

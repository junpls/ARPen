//
//  CombinationDemoScenes.swift
//  ARPen
//
//  Created by Jan on 18.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class TaskScenes {
    
    static func populateSceneBasedOnTask(scene: SCNNode, task: String, centeredAt position: SCNVector3) {
        
        var objects = [ARPNode]()
        
        switch task {
        case "Cube":
            objects = TaskScenes.cubeScene(centeredAt: position)
        case "Phone stand":
            objects = TaskScenes.phoneStandScene(centeredAt: position)
        case "Handle":
            objects = TaskScenes.handleScene(centeredAt: position)
        case "Flower pot":
            objects = TaskScenes.flowerPotScene(centeredAt: position)
        case "Door stopper":
            objects = TaskScenes.doorStopperScene(centeredAt: position)
        case "Candle holder":
            objects = TaskScenes.candleHolderScene(centeredAt: position)
        case "Spoon":
            objects = TaskScenes.spoonScene(centeredAt: position)
        case "Pen holder":
            objects = TaskScenes.penHolderScene(centeredAt: position)
        case "Combine demo":
            objects = TaskScenes.combinationDemoScene(centeredAt: position)
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
    
    static func combinationDemoScene(centeredAt positon: SCNVector3) -> [ARPNode] {
        let sphere = ARPSphere(radius: 0.02)
        sphere.position = positon + SCNVector3(-0.1, 0.02, 0)
        sphere.applyTransform()
        sphere.name = "sphere"
        
        let box = ARPBox(width: 0.09, height: 0.03, length: 0.02)
        box.position = positon + SCNVector3(0, 0.0175, 0)
        box.applyTransform()
        box.name = "box"
        
        let cylinder = ARPCylinder(radius: 0.005, height: 0.06)
        cylinder.position = positon + SCNVector3(0.1, 0.005, 0)
        cylinder.rotation = SCNVector4(0, 0, 1, Float.pi/2)
        cylinder.applyTransform()
        cylinder.name = "cylinder"
        
        return [sphere, box, cylinder]
    }
    
    static let cubeScale: Float = 1.5
    static func cubeScene(centeredAt position: SCNVector3) -> [ARPPath] {
        let d = TaskScenes.cubeScale * 0.04
       
        let profile = ARPPath(points: [
            ARPPathNode(position.x - d/2, position.y, position.z - d/2, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x - d/2, position.y, position.z + d/2, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x + d/2, position.y, position.z + d/2, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x + d/2, position.y, position.z - d/2, cornerStyle: .sharp, initFixed: true)
            ], closed: true)
        
        return [profile]
    }
    
    static let phoneStandScale: Float = 1
    static func phoneStandScene(centeredAt position: SCNVector3) -> [ARPPath] {
        let s: Float = TaskScenes.phoneStandScale
        
        let profile = ARPPath(points: [
            ARPPathNode(position.x + 0.03*s, position.y, position.z + 0.018*s, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x + 0.0125*s, position.y, position.z - 0.018*s, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x + 0.0102*s, position.y, position.z - 0.008*s, cornerStyle: .round, initFixed: true),
            ARPPathNode(position.x, position.y, position.z, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x - 0.0394*s, position.y, position.z - 0.081*s, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x - 0.088*s, position.y, position.z + 0.018*s, cornerStyle: .sharp, initFixed: true)
            ], closed: true)
        
        return [profile]
    }

    static let handleScale: Float = 1
    static func handleScene(centeredAt position: SCNVector3) -> [ARPPath] {
        let s: Float = TaskScenes.handleScale
        
        let profile = ARPPath(points: [
            ARPPathNode(position.x - 0.035*s, position.y, position.z - 0.015*s, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x - 0.035*s, position.y, position.z + 0.015*s, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x - 0.065*s, position.y, position.z + 0.015*s, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x - 0.065*s, position.y, position.z - 0.015*s, cornerStyle: .sharp, initFixed: true)
            ], closed: true)
        
        return [profile]
    }
    
    static let flowerPotScale: Float = 1
    static func flowerPotScene(centeredAt position: SCNVector3) -> [ARPPath] {
        let s: Float = TaskScenes.flowerPotScale
        
        let profile = ARPPath(points: [
            ARPPathNode(position.x - 0.018*s, position.y, position.z, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x - 0.023*s, position.y + 0.005*s, position.z, cornerStyle: .round, initFixed: true),
            ARPPathNode(position.x - 0.018*s, position.y + 0.01*s, position.z, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x - 0.032*s, position.y + 0.022*s, position.z, cornerStyle: .round, initFixed: true),
            ARPPathNode(position.x - 0.021*s, position.y + 0.064*s, position.z, cornerStyle: .round, initFixed: true),
            ARPPathNode(position.x - 0.027*s, position.y + 0.081*s, position.z, cornerStyle: .sharp, initFixed: true)
            ], closed: false)
        
        return [profile]
    }
    
    static let doorStopperScale: Float = 1
    static func doorStopperScene(centeredAt position: SCNVector3) -> [ARPPath] {
        let s: Float = TaskScenes.doorStopperScale
        
        let profile = ARPPath(points: [
            ARPPathNode(position.x - 0.03*s, position.y, position.z, cornerStyle: .sharp, initFixed: true),
            ARPPathNode(position.x - 0.045*s, position.y + 0.015*s, position.z, cornerStyle: .round, initFixed: false),
            ARPPathNode(position.x - 0.03*s, position.y + 0.03*s, position.z, cornerStyle: .sharp, initFixed: true)
            ], closed: false)
        
        return [profile]
    }
}

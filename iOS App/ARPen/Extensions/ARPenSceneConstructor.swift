//
//  SceneConstructor.swift
//  ARPen
//
//  Created by Philipp Wacker on 02.08.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

struct ARPenSceneConstructor {
    
    let numberOfBoxes = 64
    //let possibleSizes = [1,2,3,4]
    
    func preparedARPenBoxNodes(withScene scene : PenScene, andView view: ARSCNView) -> (superNode: SCNNode, boxes: [ARPenBoxNode]) {
        var boxes : [ARPenBoxNode] = []
        let superNode = SCNNode()
        
        let cubesPerDimension = Int(floor(pow(Double(numberOfBoxes), 1/3)))
        
        
        let screenCenterPosition = view.unprojectPoint(SCNVector3(x: Float(view.frame.width) / 2.0, y: Float(view.frame.height / 2.0), z: 0))
        superNode.position = screenCenterPosition
        superNode.position.z -= 0.4
        superNode.position.y -= 0.3
        
        var lookAtPoint = screenCenterPosition
        lookAtPoint.y = superNode.position.y
        superNode.look(at: lookAtPoint)
            
        //let numberOfBoxesPerSize = numberOfBoxes/possibleSizes.count
        
        var x = -0.15
        var y = 0.05
        var z = -0.25
        
        var arPenBoxNode : ARPenBoxNode
        //var remainingSizes = [(0.01,0),(0.02,0),(0.03,0),(0.04,0)]
        
        for _ in 0...cubesPerDimension {
            
            y = 0.25
            
            for _ in 0...Int(cubesPerDimension/2) {
                
                z = -0.25
                
                for _ in 0...cubesPerDimension {
                    
                    //determineBoxDimensions
                    //let randomPosition = Int(arc4random_uniform(UInt32(remainingSizes.count)))
                    let dimensionOfBox = 0.03//remainingSizes[randomPosition].0
                    //remainingSizes[randomPosition].1 += 1
                    //if remainingSizes[randomPosition].1 == numberOfBoxesPerSize {remainingSizes.remove(at: randomPosition)}
                    
                    //determineBoxPosition
                    let range = (-0.025, 0.025)
                    
                    let randomDoubleForX = drand48()
                    let randomDoubleForY = drand48()
                    let randomDoubleForZ = drand48()
                    
                    let distance = range.1 - range.0
                    let xPositionOffset = range.0 + (randomDoubleForX * distance)
                    let yPositionOffset = range.0 + (randomDoubleForY * distance)
                    let zPositionOffset = range.0 + (randomDoubleForZ * distance)
                    
                    arPenBoxNode = ARPenBoxNode.init(withPosition: SCNVector3Make(Float(x + xPositionOffset), Float(y + yPositionOffset), Float(z + zPositionOffset)), andDimension: Float(dimensionOfBox))
                    boxes.append(arPenBoxNode)
                    
                    z += 0.1
                    
                }
                
                y += 0.1
                
            }
            
            x += 0.1
            
        }
        boxes.shuffle()
        boxes.forEach({superNode.addChildNode($0)})
        return (superNode, boxes)
    }
    
    
}

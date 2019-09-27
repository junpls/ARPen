//
//  PenScene.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import SceneKit
import SceneKit.ModelIO

/**
 This is a subclass of `SCNScene`. It is used to hold the MarkerBox and centralize some methods
 */
class PenScene: SCNScene {
    
    /**
     The instance of the MarkerBox
     */
    var markerBox: MarkerBox!
    /**
     The pencil point is the node that corresponds to the real world pencil point.
     `pencilPoint.position` is always the best known position of the pencil point.
     */
    var pencilPoint =  SCNNode()
    
    //Node that carries all the drawing operations
    let drawingNode = SCNNode()
    /**
     If a marker was found in the current frame the var is true
     */
    var markerFound = true
    
    /**
     This method will convert the first ARPGeomNode into an stl and save it to the
     temporary directory. If there is none, it will save the entire scene.
     - Returns: An URL to the scene.stl file. Located in the tmp directory of the app
     */
    func share() -> URL {
        let filePath = URL(fileURLWithPath: NSTemporaryDirectory() + "/scene.stl")
        
        if let node = drawingNode.childNodes.first as? ARPGeomNode {
            node.exportStl(filePath: filePath)
        } else {
            let asset = MDLAsset(scnScene: self)
            try! asset.export(to: filePath)
        }

        return filePath
    }
    
    /**
     init. Should not be called. Is not called by SceneKit
     */
    override init() {
        super.init()
        
        setupPencilPoint()
    }
    
    /**
     This initializer will be called after `init(named:)` is called.
     */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupPencilPoint()
    }
    
    func setupPencilPoint() {
        self.pencilPoint.geometry = SCNSphere(radius: 0.002)
        self.pencilPoint.name = "PencilPoint"
        self.pencilPoint.geometry?.materials.first?.diffuse.contents = UIColor.red
        
        self.rootNode.addChildNode(self.pencilPoint)
        self.rootNode.addChildNode(self.drawingNode)
    }
    
}

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
    
    var content: SCNNode = SCNNode()
    var geometryNode: SCNNode = SCNNode()
    var isoLinesNode: SCNNode = SCNNode()

    var pivotChild: SCNNode

    var geometryColor = UIColor.init(hue: CGFloat(Float.random(in: 0...1)), saturation: 0.3, brightness: 0.9, alpha: 1)
    var lineColor = UIColor.black
    
    var highlightColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
    var selectedColor = UIColor.white


    var isHole: Bool = false {
        didSet {
            self.geometryColor = geometryColor.withAlphaComponent(isHole ? 0.5 : 1)
            self.geometryNode.geometry?.firstMaterial?.diffuse.contents = self.geometryColor
        }
    }
    
    override init() {
        self.pivotChild = SCNNode()
        super.init()
        appendVisualization()
        self.content.addChildNode(pivotChild)
        self.content.isHidden = true
        rebuild()
    }
    
    init(pivotChild:SCNNode) {
        self.pivotChild = pivotChild
        super.init()
        appendVisualization()
        self.content.addChildNode(self.pivotChild)
        self.content.isHidden = true
        rebuild()
    }
    
    private func appendVisualization() {
        self.addChildNode(content)
        self.addChildNode(geometryNode)
        self.addChildNode(isoLinesNode)
    }

    final func updateView() {
        
        let geom  = OCCTAPI.shared.triangulate(handle: occtReference!)
        let lines = OCCTAPI.shared.tubeframe(handle: occtReference!)
        
        /// The node may have been transformed between the geometry's generation and the actual attachment in DispatchQueue.main.async
        /// transformDelta is used to capture this difference
        
        /*
        let transformDelta = SCNNode()
        self.addChildNode(transformDelta)
        transformDelta.setWorldTransform(SCNMatrix4Identity)
        */
        
        DispatchQueue.main.async {
            self.geometryNode.geometry = geom
            self.geometryNode.geometry?.firstMaterial?.diffuse.contents = self.geometryColor
            self.geometryNode.geometry?.firstMaterial?.emission.contents = self.highlightColor
            self.geometryNode.geometry?.firstMaterial?.lightingModel = .blinn
            self.geometryNode.geometry?.firstMaterial?.diffuse.intensity = 1;
            self.updateHighlightedState()
            self.isoLinesNode.geometry = lines
            self.isoLinesNode.geometry?.firstMaterial?.diffuse.contents = self.lineColor
            self.isoLinesNode.geometry?.firstMaterial?.emission.contents = self.selectedColor
            self.isoLinesNode.geometry?.firstMaterial?.lightingModel = .constant
            self.updateSelectedState()
            //self.isoLinesNode.geometry?.firstMaterial?.readsFromDepthBuffer = false
            //self.geometryNode.renderingOrder = -1
            
            /// This is necessary for world coordinates
            //self.geometryNode.setWorldTransform(transformDelta.worldTransform)
            //self.isoLinesNode.setWorldTransform(transformDelta.worldTransform)
            //transformDelta.removeFromParentNode()
            
            //self.geometryNode.transform = SCNMatrix4Invert(self.content.transform)
            //self.isoLinesNode.transform = SCNMatrix4Invert(self.content.transform)
        }
    }
    
    /// Call to apply changes in translation, rotation or scale to OCCT.
    override func applyTransform() {
        self.applyTransform_()
        (parent?.parent as? ARPGeomNode)?.rebuild()
    }
    
    private final func applyTransform_() {
        /// This was necessary for local coordinates
        //OCCTAPI.shared.transform(handle: occtReference!, transformation: self.transform)
        
        /// This is necessary for world coordinates
        OCCTAPI.shared.transform(handle: occtReference!, transformation: self.worldTransform)
        for c in content.childNodes {
            if let geom = c as? ARPGeomNode {
                geom.applyTransform_()
            }
        }
    }
    
    /// This method is responsible for creating the geometry, s.t. it has its origin at (0,0,0). Therefore you have to ensure to either create it there, or to manually shift the origin using OCCTAPI.shared.pivot. What's more appropriate depends on the situation.
    func build() throws -> OCCTReference {
        fatalError("Must Override")
    }
    
    final func rebuild() {
        if let ref = occtReference {
            OCCTAPI.shared.free(handle: ref)
        }
        if let ref = try? build() {
            occtReference = ref
            pivotToChild()
            updateView()
            (parent?.parent as? ARPGeomNode)?.rebuild()
        } else {
            print("FAILED TO REBUILD")
        }
    }
    
    final func pivotToChild() {
        /*
        /// Changing the pivot in SceneKit has two oddities:
        /// (1) The node shifts, s.t. the node's pivot stays in the same place relative to the scene
        /// (2) The node's internal coordinate system does not change. Its position does however. Pivot != origin in SceneKit
        
        /// Because of (1), we *first* transform the object to the same world space transform as the child to be pivot...
         self.setWorldTransform(child.worldTransform)
        /// ... and then change its pivot. Otherwise the child objects would have already been moved relative to the scene.
        self.pivot = child.transform
         */
        self.setWorldTransform(pivotChild.worldTransform)
        content.transform = SCNMatrix4Invert(pivotChild.transform)
    }
    
    override func updateHighlightedState() {
        if highlighted {
            geometryNode.geometry?.firstMaterial?.emission.intensity = 1
        } else {
            geometryNode.geometry?.firstMaterial?.emission.intensity = 0
        }
    }
    
    override func updateSelectedState() {
        if selected {
            isoLinesNode.geometry?.firstMaterial?.emission.intensity = 1
        } else {
            isoLinesNode.geometry?.firstMaterial?.emission.intensity = 0
        }
    }
    
    override func updateVisitedState() {
        self.content.isHidden = !visited
        self.geometryNode.isHidden = visited
        self.isoLinesNode.isHidden = visited
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        OCCTAPI.shared.free(handle: occtReference!)
    }
}

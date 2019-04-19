//
//  ArrangePlugin.swift
//  ARPen
//
//  Created by Jan on 19.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//
import ARKit

class ArrangePlugin: Plugin {
    
    var pluginImage : UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Arrange"
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    
    private var buttonEvents: ButtonEvents
    
    init() {
        buttonEvents = ButtonEvents()
        buttonEvents.didPressButton = self.didPressButton
        buttonEvents.didReleaseButton = self.didReleaseButton
    }

    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentView = view
        self.currentScene = scene
    }
    
    func deactivatePlugin() {
        
    }
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
    }
    
    func didPressButton(_ button: Button) {
        
    }
    
    func didReleaseButton(_ button: Button) {
        
    }
    
    func hitTest(pointerPosition: SCNVector3) -> [SCNHitTestResult] {
        guard let sceneView = self.currentView  else { return [] }
        let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
        let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
        
        //cast a ray from that position and find the first ARPenNode
        let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
        
        return hitResults.filter( { $0.node != currentScene?.pencilPoint } )
    }
}

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
    
    
    static let timeTillDrag: Double = 0.5
    static let maxDistanceTillDrag: Float = 0.01
    
    private var hoverTarget: ARPGeomNode?
    private var selectedTargets: [ARPGeomNode] = []
    private var dragging: Bool = false
    private var buttonEvents: ButtonEvents
    private var justSelectedSomething = false
    
    private var lastClickPosition: SCNVector3?
    private var lastClickTime: Date?
    private var lastPenPosition: SCNVector3?

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
        for target in selectedTargets {
            unSelectTarget(target)
        }
    }
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        

        for node in scene.drawingNode.childNodes {
            if let arpGeom = node as? ARPGeomNode, !selectedTargets.contains(arpGeom) {
                arpGeom.highlighted = false
            }
        }
        hoverTarget = nil
        
        if let hitTestResult = hitTest(pointerPosition: scene.pencilPoint.position).first,
            let hit = hitTestResult.node.parent as? ARPGeomNode {
                hit.highlighted = true
                hoverTarget = hit
        }
        
        if (buttons[.Button1] ?? false) &&
            ((Date() - (lastClickTime ?? Date())) > ArrangePlugin.timeTillDrag
                || (lastPenPosition?.distance(vector: scene.pencilPoint.position) ?? 0) > ArrangePlugin.maxDistanceTillDrag) {
            dragging = true
        }
        
        if dragging, let lastPos = lastPenPosition {
            for target in selectedTargets {
                target.position += scene.pencilPoint.position - lastPos
            }
        }
        
        lastPenPosition = scene.pencilPoint.position
    }
    
    func didPressButton(_ button: Button) {

        switch button {
        case .Button1:
            lastClickPosition = currentScene?.pencilPoint.position
            lastClickTime = Date()
            
            if let target = hoverTarget {
                if !selectedTargets.contains(target) {
                    selectTarget(target)
                }
            } else {
                selectedTargets = []
            }
        case .Button2, .Button3:
            if selectedTargets.count == 2 {
                let a = selectedTargets.removeFirst()
                let b = selectedTargets.removeFirst()
                
                DispatchQueue.global(qos: .userInitiated).async {
                    if let diff = try? ARPBoolNode(a: a, b: b, operation: button == .Button2 ? .join : .cut) {
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(diff)
                        }
                    }
                }
            }
        }
    }
    
    func didReleaseButton(_ button: Button) {
        if dragging {
            for target in selectedTargets {
                target.applyTransform()
            }
        } else {
            if let target = hoverTarget, !justSelectedSomething {
                if selectedTargets.contains(target) {
                    unSelectTarget(target)
                }
            }
        }
        justSelectedSomething = false
        dragging = false
    }
    
    func selectTarget(_ target: ARPGeomNode) {
        target.highlighted = true
        selectedTargets.append(target)
        justSelectedSomething = true
    }
    
    func unSelectTarget(_ target: ARPGeomNode) {
        target.highlighted = false
        selectedTargets.removeAll(where: { $0 === target })
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

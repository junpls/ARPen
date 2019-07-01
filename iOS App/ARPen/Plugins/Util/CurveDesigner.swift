//
//  CurveDesigner.swift
//  ARPen
//
//  Created by Jan on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class CurveDesigner {
    
    static let snappingDistance: Float = 0.01
    static let minNextPointDistance: Float = 0.02
    
    var didStartPath: ((ARPPath) -> Void)?
    var didCompletePath: ((ARPPath) -> Void)?

    var activePath: ARPPath? = nil
    
    private var blocked: Bool = false
    private var busy: Bool = false
    private var scene: PenScene!
    
    private var buttonEvents: ButtonEvents
    
    private var addedThisFrame: Bool = false

    init() {
        buttonEvents = ButtonEvents()
        buttonEvents.didPressButton = self.didPressButton
        buttonEvents.didReleaseButton = self.didReleaseButton
    }
    
    func update(scene: PenScene, buttons: [Button : Bool]) {
        self.scene = scene
        addedThisFrame = false
        buttonEvents.update(buttons: buttons)
        
        if let path = activePath {
            if path.points.first!.position.distance(vector: scene.pencilPoint.position) < CurveDesigner.snappingDistance && path.points.count > 2 {
                path.getNonFixedPoint()?.position = path.points.first!.worldPosition
                if buttonEvents.buttons[.Button2]! || buttonEvents.buttons[.Button3]! {
                    addNode(noNewPath: true)
                }
            } else {
                path.getNonFixedPoint()?.position = scene.pencilPoint.position
            }
            
            if let nonFixed = path.getNonFixedPoint() {
                nonFixed.active = scene.markerFound
            }
            
            tryRebuildPreview()
        }
        
        if (buttonEvents.buttons[.Button2]! || buttonEvents.buttons[.Button3]!) && readyForNextPoint() {
            addNode(noNewPath: true)
        }
    }
    
    func undo() {
        if let path = self.activePath {
            path.removeLastPoint()
            if let last = path.points.last {
                last.fixed = false
            } else {
                self.activePath = nil
            }
        }
    }
    
    func injectUIButtons(_ buttons: [Button : UIButton]) {
        buttons[.Button1]?.setTitle("Finish", for: .normal)
        buttons[.Button2]?.setTitle("Sharp corner", for: .normal)
        buttons[.Button3]?.setTitle("Round corner", for: .normal)
    }
    
    private func didPressButton(_ button: Button) {
        switch button {
        case .Button1:
            finishActivePath()
        case .Button2, .Button3:
            addNode()
        }
    }
    
    private func didReleaseButton(_ button: Button) {
        blocked = false
        /*
        switch button {
        case .Button1:
            break
        case .Button2, .Button3:
            if let path = activePath, path.points.count > 2 && path.closed {
                finishActivePath()
            }
        }*/
    }
    
    private func addNode(noNewPath: Bool = false) {
        if addedThisFrame {
            return
        }
        addedThisFrame = true
        let cornerStyle = buttonEvents.buttons[.Button2]! ? CornerStyle.sharp : CornerStyle.round
        
        if activePath == nil && !noNewPath {
            let path = ARPPath(points: [ARPPathNode(scene.pencilPoint.position, cornerStyle: cornerStyle)], closed: false)
            activePath = path
            scene.drawingNode.addChildNode(path)
            didStartPath?(path)
        }
        
        if let path = activePath {
            if pathEndsTouch(path) {
                finishActivePath()
            } else {
                let activePoint = path.getNonFixedPoint()
                if cornerStyle == activePoint?.cornerStyle {
                    activePoint?.fixed = true
                    path.appendPoint(ARPPathNode(scene.pencilPoint.position, cornerStyle: cornerStyle))
                } else {
                    activePoint?.cornerStyle = cornerStyle
                    blocked = true
                }
            }
        }
    }
    
    private func pathEndsTouch(_ path: ARPPath) -> Bool {
        if let nonFixedPoint = path.getNonFixedPoint(), path.points.count > 2 {
            if path.points.first!.worldPosition.distance(vector: nonFixedPoint.worldPosition) < CurveDesigner.snappingDistance {
                return true
            }
        }
        return false
    }
    
    private func finishActivePath() {
        if let path = activePath {
            if pathEndsTouch(path) {
                path.closed = true
//                path.flatten()
            }
            path.removeNonFixedPoints()
            path.rebuild()
            path.runAction(ARPPath.finalizeAnimation)
            activePath = nil
            
            didCompletePath?(path)
        }
    }
    
    func readyForNextPoint() -> Bool {
        if let path = activePath,
            let lastFixed = path.points.last(where: { $0.fixed }),
            let lastFree = path.points.last(where: { !$0.fixed }) {
            if lastFree.worldPosition.distance(vector: lastFixed.worldPosition) < CurveDesigner.minNextPointDistance {
                return false
            }
        }
        return !blocked
    }
    
    func tryRebuildPreview() {
        if !busy, let path = activePath {
            busy = true
            DispatchQueue.global(qos: .userInitiated).async {
                path.rebuild()
                self.busy = false
            }
        }
    }
}

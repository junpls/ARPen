//
//  CurveDesigner.swift
//  ARPen
//
//  Created by Jan on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class CurveDesigner {
    
    static let maxClosureDistance: Float = 0.01
    static let minNextPointDistance: Float = 0.02
    
    var didStartPath: ((ARPPath) -> Void)?
    var didCompletePath: ((ARPPath) -> Void)?

    var activePath: ARPPath? = nil
    
    private var blocked: Bool = false
    private var busy: Bool = false
    private var scene: PenScene!
    
    private var buttonEvents: ButtonEvents
    
    init() {
        buttonEvents = ButtonEvents()
        buttonEvents.didPressButton = self.didPressButton
        buttonEvents.didReleaseButton = self.didReleaseButton
    }
    
    func update(scene: PenScene, buttons: [Button : Bool]) {
        self.scene = scene
        buttonEvents.update(buttons: buttons)
        
        if ((buttonEvents.buttons[.Button2]! || buttonEvents.buttons[.Button3]!) && readyForNextPoint()) {
            addNode()
        }
        
        if let path = activePath {
            path.getNonFixedPoint()?.position = scene.pencilPoint.position
            tryRebuildPreview()
        }
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
    }
    
    private func addNode() {
        let cornerStyle = buttonEvents.buttons[.Button2]! ? CornerStyle.sharp : CornerStyle.round
        
        if activePath == nil {
            let path = ARPPath(points: [ARPPathNode(scene.pencilPoint.position, cornerStyle: cornerStyle)], closed: false)
            activePath = path
            scene.drawingNode.addChildNode(path)
            didStartPath?(path)
        }
        
        if let path = activePath {
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
    
    private func finishActivePath() {
        if let path = activePath {
            if path.points.first!.worldPosition.distance(vector: path.points.last!.worldPosition) < CurveDesigner.maxClosureDistance {
                path.closed = true
                path.flatten()
            }
            path.removeNonFixedPoints()
            path.rebuild()
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
                if path.points.first!.worldPosition.distance(vector: path.points.last!.worldPosition) < CurveDesigner.maxClosureDistance {
                    path.closed = true
                } else {
                    path.closed = false
                }
                path.rebuild()
                self.busy = false
            }
        }
    }
}

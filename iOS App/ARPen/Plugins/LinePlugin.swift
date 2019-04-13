//
//  LinePlugin.swift
//  ARPen
//
//  Created by Jan on 04.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class LinePlugin: Plugin {
    
    var pluginImage : UIImage?// = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "Lines"
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    
    let maxClosureDistance: Float = 0.01
    let minNextPointDistance: Float = 0.03
    
    private var activePath: ARPPath? = nil
    
    private var freePaths: [ARPPath] = [ARPPath]()
    
    private var currentButtonStates: [Button : Bool] = [:]
    private var previousButtonStates: [Button : Bool] = [:]
    
    private var busy: Bool = false
    
    private var scene: PenScene?
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        self.scene = scene
        currentButtonStates = buttons
        
        if ((buttons[.Button2]! || buttons[.Button3]!) && readyForNextPoint())
            || buttonPressed(.Button2) || buttonPressed(.Button3) {
            
            let cornerStyle = buttons[.Button2]! ? CornerStyle.sharp : CornerStyle.round
            
            if activePath == nil {
                let path = ARPPath(points: [ARPPathNode(scene.pencilPoint.position, cornerStyle: cornerStyle)], closed: false)
                activePath = path
                scene.drawingNode.addChildNode(path)
            }
            
            if let path = activePath {
                let activePoint = path.getNonFixedPoint()
                activePoint?.cornerStyle = cornerStyle
                activePoint?.fixed = true
                path.appendPoint(ARPPathNode(scene.pencilPoint.position, cornerStyle: cornerStyle))
            }
        }
        
        if buttonPressed(.Button1), let path = activePath {
            if path.points.first!.worldPosition.distance(vector: path.points.last!.worldPosition) < maxClosureDistance {
                path.closed = true
                path.flatten()
            }
            path.removeNonFixedPoints()
            path.rebuild()
            freePaths.append(path)
            activePath = nil
            
            tryToSweep()
            tryToRevolve()
        }
        
        if let path = activePath {
            path.points.last?.position = scene.pencilPoint.position
            tryRebuildPreview()
        }

        self.previousButtonStates = buttons
    }
    
    func tryToSweep() {
        if let profile = freePaths.first(where: { $0.closed }),
            let path = freePaths.first(where: { !$0.closed }) {
            if let sweep = try? ARPSweep(profile: profile, path: path) {
                scene?.drawingNode.addChildNode(sweep)
                freePaths.removeAll(where: { $0 === profile || $0 === path })
            }
        }
    }
    
    func tryToRevolve() {
        if let profile = freePaths.first(where: { !$0.closed }) {
            if let revolution = try? ARPRevolution(profile: profile) {
                scene?.drawingNode.addChildNode(revolution)
                freePaths.removeAll(where: { $0 === profile })
            }
        }
    }

    func buttonPressed(_ button:Button) -> Bool {
        if let n = currentButtonStates[button], let p = previousButtonStates[button] {
            return n && !p
        } else {
            return false
        }
    }
    
    func buttonReleased(_ button:Button) -> Bool {
        if let n = currentButtonStates[button], let p = previousButtonStates[button] {
            return !n && p
        } else {
            return false
        }
    }
    
    func readyForNextPoint() -> Bool {
        if let path = activePath,
            let lastFixed = path.points.last(where: { $0.fixed }),
            let lastFree = path.points.last(where: { !$0.fixed }) {
            if lastFree.worldPosition.distance(vector: lastFixed.worldPosition) < minNextPointDistance {
                return false
            }
        }
        return true
    }
    
    func tryRebuildPreview() {
        if !busy, let path = activePath {
            busy = true
            DispatchQueue.global(qos: .userInitiated).async {
                if path.points.first!.worldPosition.distance(vector: path.points.last!.worldPosition) < self.maxClosureDistance {
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

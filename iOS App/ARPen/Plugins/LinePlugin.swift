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
    
    let maxClosureDistance: Float = 0.02
    
    private var activePath: ARPPath? = nil
    
    private var freePaths: [ARPPath] = [ARPPath]()
    
    private var currentButtonStates: [Button : Bool] = [:]
    private var previousButtonStates: [Button : Bool] = [:]
    
    private var busy: Bool = false
    
    private var scene: PenScene?
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        self.scene = scene
        currentButtonStates = buttons
        
        if buttonPressed(.Button1) {
            
            if activePath == nil {
                let path = ARPPath(points: [scene.pencilPoint.position], closed: false)
                activePath = path
                scene.drawingNode.addChildNode(path)
            }
            
            if let path = activePath {
                path.appendPoint(scene.pencilPoint.position)
                path.rebuild()
            }
        }
        
        if buttonPressed(.Button2), let path = activePath {
            if path.points.first!.position.distance(vector: path.points[path.points.count-2].position) < maxClosureDistance {
                path.removeLastPoint()
                path.closed = true
            }
            path.removeLastPoint()
            path.flatten()
            path.rebuild()
            freePaths.append(path)
            activePath = nil
            
            tryToSweep()
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

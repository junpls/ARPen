//
//  ARPNode.swift
//  Loop
//
//  Created by Jan on 15.02.19.
//  Copyright © 2019 Jan. All rights reserved.
//

import Foundation

class ARPNode: SCNNode {
    
    var highlighted: Bool = false {
        didSet {
            updateHighlightedState()
        }
    }
    
    var selected: Bool = false {
        didSet {
            updateSelectedState()
        }
    }
    
    var visited: Bool = false {
        didSet {
            updateVisitedState()
        }
    }
    
    func isRootNode() -> Bool {
        return (parent as? ARPNode) == nil
    }
    
    func updateHighlightedState() {}
    
    func updateSelectedState() {}
    
    func updateVisitedState() {}
    
    func applyTransform() {}
}

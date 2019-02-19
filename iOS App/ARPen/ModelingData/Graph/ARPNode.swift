//
//  ARPNode.swift
//  Loop
//
//  Created by Jan on 15.02.19.
//  Copyright © 2019 Jan. All rights reserved.
//

import Foundation

class ARPNode: SCNNode {
    
    func isRootNode() -> Bool {
        return (parent as? ARPNode) == nil
    }
}

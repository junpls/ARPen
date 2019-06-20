//
//  UIButtonPlugin.swift
//  ARPen
//
//  Created by Jan on 20.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

protocol UIButtonPlugin {
    var penButtons: [Button: UIButton]! { get set }
    var undoButton: UIButton! { get set }
}

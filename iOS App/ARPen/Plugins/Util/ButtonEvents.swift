//
//  ButtonEvents.swift
//  ARPen
//
//  Created by Jan on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class ButtonEvents {
    
    var didPressButton: ((Button) -> Void)?
    var didReleaseButton: ((Button) -> Void)?

    private var pressedThisFrame: [Button : Bool] = [:]
    private var releasedThisFrame: [Button : Bool] = [:]
    
    var buttons: [Button : Bool] = [:]
    private var previousButtons: [Button : Bool] = [:]
    
    func update(buttons: [Button : Bool]) {
        self.buttons = buttons
        
        for (button, _) in buttons {
            pressedThisFrame[button] = false
            releasedThisFrame[button] = false
            
            if buttonPressed(button) {
                pressedThisFrame[button] = true
                didPressButton?(button)
            } else if buttonReleased(button) {
                releasedThisFrame[button] = true
                didReleaseButton?(button)
            }
        }
        
        previousButtons = buttons
    }
    
    private func buttonPressed(_ button: Button) -> Bool {
        if let n = buttons[button], let p = previousButtons[button] {
            return n && !p
        } else {
            return false
        }
    }
    
    private func buttonReleased(_ button: Button) -> Bool {
        if let n = buttons[button], let p = previousButtons[button] {
            return !n && p
        } else {
            return false
        }
    }
    
    func justPressed(_ button: Button) -> Bool {
        return pressedThisFrame[button] ?? false
    }
    
    func justReleased(_ button: Button) -> Bool {
        return releasedThisFrame[button] ?? false
    }
}

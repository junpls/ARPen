//
//  Menu.swift
//  ARPen
//
//  Created by Oliver Nowak on 15.11.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

class Menu {
    
    var items: [Any] = []
    var count: Int {
        get { return items.count }
    }
    
    
    
    init(items: [Any]) {
        self.items = items
    }
}

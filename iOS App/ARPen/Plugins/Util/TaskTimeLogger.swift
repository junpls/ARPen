//
//  TaskTimeLogger.swift
//  ARPen
//
//  Created by Jan on 14.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class TaskTimeLogger {

    var defaultDict = [String: String]()
    private var startTime: Date?
    
    func startUnlessRunning() {
        if startTime == nil {
            startTime = Date()
        }
    }
    
    func finish() -> [String:String]  {
        if let startTime = self.startTime {
            let duration = Date().timeIntervalSince(startTime)
            self.startTime = nil
            
            
            var targetMeasurementDict = defaultDict
            targetMeasurementDict["TaskTime"] = String(describing: duration)
            return targetMeasurementDict
        } else {
            return defaultDict
        }

    }
}

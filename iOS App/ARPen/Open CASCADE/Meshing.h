//
//  Meshing.h
//  ARPen
//
//  Created by Jan on 27.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

#ifndef Meshing_h
#define Meshing_h

#include <SceneKit/SceneKit.h>

@interface Meshing : NSObject

+ (SCNGeometry *) sceneKitMeshOf:(const char *) label;
+ (SCNGeometry *) sceneKitLinesOf:(const char *) label;
+ (SCNGeometry *) sceneKitTubesOf:(const char *) label;
+ (void) stlOf:(const char *) label
        toFile:(const char *) filename;

@end

#endif /* Meshing_h */

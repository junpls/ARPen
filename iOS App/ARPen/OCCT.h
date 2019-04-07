//
//  Header.h
//  Loop
//
//  Created by Jan on 25.01.19.
//  Copyright © 2019 Jan. All rights reserved.
//

#ifndef OCCT_h
#define OCCT_h

#include <UIKit/UIKit.h>
#include <SceneKit/SceneKit.h>

@interface OCCT : NSObject

@property (strong, nonatomic) id someProperty;

- (void) someMethod;

- (const char *) createCube;
- (const char *) createFlask;

- (const char *) createSphere:(double) radius;
- (const char *) createBox:(double) width
                    height:(double) height
                    length:(double) length;
- (const char *) createPath:(const SCNVector3 []) points
                     length:(int) length
                     closed:(bool) closed;

- (const char *) sweep:(const char *) profile
                 along:(const char *) path;

- (const char *) booleanCut:(const char *) a
                   subtract:(const char *) b;

- (const char *) booleanJoin:(const char *) a
                        with:(const char *) b;

- (const char *) booleanIntersect:(const char *) a
                             with:(const char *) b;


- (SCNVector3) center:(const char *) label;

- (const SCNVector3 *) flattened:(const SCNVector3 []) points
                        ofLength:(int) length;
- (int) coincidentDimensionsOf:(const SCNVector3 []) points
                      ofLength:(int) length;

- (void) setTransformOf:(const char *) label
         transformation:(SCNMatrix4) mat;
- (void) setPivotOf:(const char *) label
              pivot:(SCNMatrix4) mat;

- (SCNGeometry *) sceneKitMeshOf:(const char *) label;
- (SCNGeometry *) sceneKitLinesOf:(const char *) label;
- (SCNGeometry *) sceneKitTubesOf:(const char *) label;
- (void) freeShape:(const char *) label;

@end

#endif /* OCCT_h */

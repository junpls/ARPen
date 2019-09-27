//
//  Helpers.h
//  ARPen
//
//  Created by Jan on 27.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

#ifndef Helpers_h
#define Helpers_h

#include <SceneKit/SceneKit.h>

#include <TColgp_Array1OfPnt.hxx>
#include <gp_Pln.hxx>

@interface Helpers : NSObject

+ (void) setGTransformOf:(const char *) label
                  affine:(SCNMatrix4) affine
             translation:(SCNVector3) translation;
+ (void) setTransformOf:(const char *) label
         transformation:(SCNMatrix4) mat;
+ (void) setPivotOf:(const char *) label
              pivot:(SCNMatrix4) mat;

+ (SCNVector3) center:(const char *) label;

+ (const SCNVector3 *) flattened:(const SCNVector3 []) points
                        ofLength:(int) length;

+ (SCNVector3) circleCenterOf:(const SCNVector3 []) points
                     ofLength:(int) length;
+ (SCNVector3) pc1Of:(const SCNVector3 []) points
            ofLength:(int) length;
+ (int) coincidentDimensionsOf:(const SCNVector3 [])points
                      ofLength:(int)length;

+ (gp_Pln) projectOntoPlane:(const TColgp_Array1OfPnt&) ocPoints;

+ (TColgp_Array1OfPnt) convertPoints:(const SCNVector3 []) points
                            ofLength:(int) length;


@end

#endif /* Helpers_h */

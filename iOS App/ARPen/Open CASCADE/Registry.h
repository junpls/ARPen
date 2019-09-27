//
//  Registry.h
//  ARPen
//
//  Created by Jan on 27.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

#ifndef Registry_h
#define Registry_h

#include <TopoDS_Shape.hxx>
#include <TCollection_AsciiString.hxx>
#include <gp_Trsf.hxx>

@interface Registry : NSObject

+ (TCollection_AsciiString) randomString;
+ (const char *) toHeapString:(TCollection_AsciiString) input;

+ (TCollection_AsciiString) storeInRegistry:(TopoDS_Shape &) shape;
+ (void) storeInRegistry:(TopoDS_Shape &) shape
                 withKey:(TCollection_AsciiString) key;
+ (const char *) storeInRegistryWithCString:(TopoDS_Shape &) shape;
+ (void) storeInTransformRegistry:(gp_Trsf &) transform
                          withKey:(TCollection_AsciiString) key;

+ (void) freeShape:(const char *) label;
+ (void) deleteFromRegistry:(TCollection_AsciiString) key;

+ (TopoDS_Shape) retrieveFromRegistry:(TCollection_AsciiString) key;
+ (TopoDS_Shape) retrieveFromRegistryWithCString:(const char *) label;
+ (TopoDS_Shape) retrieveFromRegistryTransformed:(TCollection_AsciiString) key;

@end

#endif /* Registry_h */

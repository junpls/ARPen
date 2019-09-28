//
//  Registry.m
//  ARPen
//
//  Created by Jan on 27.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "Registry.h"

#include <occt/TopoDS_Shape.hxx>
#include <occt/TCollection_AsciiString.hxx>
#include <occt/NCollection_DataMap.hxx>
#include <occt/gp_Trsf.hxx>
#include <occt/BRepBuilderAPI_Transform.hxx>

@implementation Registry : NSObject

static NCollection_DataMap<TCollection_AsciiString, TopoDS_Shape> shapeRegistry = NCollection_DataMap<TCollection_AsciiString, TopoDS_Shape>();
static NCollection_DataMap<TCollection_AsciiString, gp_Trsf> transformRegistry = NCollection_DataMap<TCollection_AsciiString, gp_Trsf>();

+ (TCollection_AsciiString) randomString {
    static int length = 32;
    char s[length + 1];
    
    static const char alphanum[] =
        "0123456789"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "abcdefghijklmnopqrstuvwxyz";
    
    for (int i = 0; i < length; ++i) {
        s[i] = alphanum[rand() % (sizeof(alphanum) - 1)];
    }
    
    s[length] = 0;
    TCollection_AsciiString res = TCollection_AsciiString(s);
    return res;
}

+ (const char *) toHeapString:(TCollection_AsciiString) input {
    const char *conv = input.ToCString();
    char *res = new char[strlen(conv) + 1];
    std::copy(conv, conv + strlen(conv) + 1, res);
    return res;
}

+ (TCollection_AsciiString) storeInRegistry:(TopoDS_Shape &) shape {
    TCollection_AsciiString key = [self randomString];
    shapeRegistry.Bind(key, shape);
    return key;
}

+ (void) storeInRegistry:(TopoDS_Shape &) shape
                 withKey:(TCollection_AsciiString) key {
    shapeRegistry.Bind(key, shape);
}

+ (void) deleteFromRegistry:(TCollection_AsciiString) key {
    shapeRegistry.UnBind(key);
    transformRegistry.UnBind(key);
}

+ (const char *) storeInRegistryWithCString:(TopoDS_Shape &) shape {
    TCollection_AsciiString key = [self randomString];
    shapeRegistry.Bind(key, shape);
    return [self toHeapString:key];
}

+ (void) storeInTransformRegistry:(gp_Trsf &) transform
                          withKey:(TCollection_AsciiString) key {
    transformRegistry.Bind(key, transform);
}


+ (TopoDS_Shape) retrieveFromRegistry:(TCollection_AsciiString) key {
    return shapeRegistry.Find(key);
}

+ (TopoDS_Shape) retrieveFromRegistryWithCString:(const char *) label {
    TCollection_AsciiString key = TCollection_AsciiString(label);
    return [self retrieveFromRegistry:key];
}

+ (TopoDS_Shape) retrieveFromRegistryTransformed:(TCollection_AsciiString) key {
    TopoDS_Shape shape = shapeRegistry.Find(key);
    gp_Trsf trans;
    try {
        // OCC_CATCH_SIGNALS
        trans = transformRegistry.Find(key);
    } catch (...) {
        trans = gp_Trsf();
    }
    // May be dangerous! If undesired behaviour occurs, try changing to Standard_True
    BRepBuilderAPI_Transform builder(shape, trans, Standard_False);
    return builder.Shape();
}

+ (void) freeShape:(const char *) label {
    TopoDS_Shape shape = [self retrieveFromRegistryWithCString:label];
    shape.Nullify();
    TCollection_AsciiString key = TCollection_AsciiString(label);
    [self deleteFromRegistry:key];
}

@end

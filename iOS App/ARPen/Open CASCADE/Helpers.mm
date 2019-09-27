//
//  Helpers.mm
//  ARPen
//
//  Created by Jan on 27.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//
#import <Foundation/Foundation.h>

#include "Helpers.h"

#include "Registry.h"

#include <BRepBuilderAPI_GTransform.hxx>
#include <BRepBuilderAPI_Transform.hxx>
#include <Bnd_Box.hxx>
#include <BRepBndLib.hxx>
#include <Geom_Plane.hxx>
#include <GeomAPI_ProjectPointOnSurf.hxx>
#include <GeomAPI_ProjectPointOnSurf.hxx>
#include <math_GaussLeastSquare.hxx>
#include <GProp_PrincipalProps.hxx>
#include <GProp_PGProps.hxx>
#include <GProp_PEquation.hxx>

@implementation Helpers : NSObject

static const double flatteningTolerance = 0.01;

+ (void) setGTransformOf:(const char *) label
                  affine:(SCNMatrix4) affine
             translation:(SCNVector3) translation {
    
    TCollection_AsciiString key(label);
    TopoDS_Shape shape = [Registry retrieveFromRegistry:key];
    gp_Mat affineMat(affine.m11, affine.m13, affine.m12, affine.m21, affine.m23, affine.m22, affine.m31, affine.m33, affine.m32);
    gp_XYZ transVec(translation.x, translation.z, translation.y);
    gp_GTrsf trans(affineMat, transVec);

    /*
    gp_Trsf move;
    move.SetTranslation(gp_Vec(transform.x, transform.z, transform.y));
     */
    //shape.Location(TopLoc_Location(move));
    
    BRepBuilderAPI_GTransform builder(shape, trans, Standard_True);
    TopoDS_Shape newShape = builder.ModifiedShape(shape);
    
    [Registry deleteFromRegistry:key];
    [Registry storeInRegistry:newShape withKey:key];
}

+ (void) setTransformOf:(const char *) label
         transformation:(SCNMatrix4) mat {
    TCollection_AsciiString key(label);
    gp_Trsf trans;
    trans.SetValues(mat.m11, mat.m21, mat.m31, mat.m41, mat.m12, mat.m22, mat.m32, mat.m42, mat.m13, mat.m23, mat.m33, mat.m43);
    [Registry storeInTransformRegistry:trans withKey:key];
}

+ (void) setPivotOf:(const char *) label
              pivot:(SCNMatrix4) mat {
    
    TCollection_AsciiString key = TCollection_AsciiString(label);
    TopoDS_Shape shape = [Registry retrieveFromRegistry: key];

    gp_Trsf trans;
    trans.SetValues(mat.m11, mat.m21, mat.m31, mat.m41, mat.m12, mat.m22, mat.m32, mat.m42, mat.m13, mat.m23, mat.m33, mat.m43);
    gp_Trsf transInv = trans.Inverted();
    BRepBuilderAPI_Transform trsf(shape, transInv);
    
    TopoDS_Shape newShape = trsf.Shape();
    [Registry storeInRegistry:newShape withKey:key];
    [Registry storeInTransformRegistry:trans withKey:key];
}

+ (SCNVector3) center:(const char *) label {
    
    TCollection_AsciiString key = TCollection_AsciiString(label);
    TopoDS_Shape shape = [Registry retrieveFromRegistry: key];
    
    /// Update the incremental mesh
    // BRepMesh_IncrementalMesh mesh(shape, linearDeflection);
    
    Bnd_Box B;
    BRepBndLib::Add(shape, B, Standard_False);
    Standard_Real Xmin, Ymin, Zmin, Xmax, Ymax, Zmax;
    B.Get(Xmin, Ymin, Zmin, Xmax, Ymax, Zmax);
    
    SCNVector3 newCenter = SCNVector3Make((float) ((Xmin+Xmax)/2), (float) ((Ymin+Ymax)/2), (float) ((Zmin+Zmax)/2));
    
    gp_Trsf move;
    move.SetTranslation(gp_Vec(-newCenter.x, -newCenter.y, -newCenter.z));
    BRepBuilderAPI_Transform trsf(shape, move);
    
    TopoDS_Shape newShape = trsf.Shape();
    
    [Registry storeInRegistry:newShape withKey:key];

    return newCenter;
}

+ (const SCNVector3 *) flattened:(const SCNVector3 []) points
                        ofLength:(int) length
{
    TColgp_Array1OfPnt ocPoints = [self convertPoints:points ofLength:length];
    
    gp_Pln pln = [self projectOntoPlane:ocPoints];
    Handle(Geom_Plane) plane = new Geom_Plane(pln);
    
    for (int i = 1; i <= length; i++) {
        GeomAPI_ProjectPointOnSurf proj = GeomAPI_ProjectPointOnSurf(ocPoints.Value(i), plane);
        ocPoints.SetValue(i, proj.Point(1));
    }
    
    SCNVector3 *res = new SCNVector3[length];
    for (int i = 1; i <= length; i++) {
        gp_Pnt pt = ocPoints.Value(i);
        res[i-1] = {(float)pt.X(), (float)pt.Y(), (float)pt.Z()};
    }
    
    return res;
}

+ (SCNVector3) circleCenterOf:(const SCNVector3 []) points
                     ofLength:(int) length
{
    TColgp_Array1OfPnt ocPoints = [self convertPoints:points ofLength:length];
    
    gp_Pln pln = [self projectOntoPlane:ocPoints];
    Handle(Geom_Plane) plane = new Geom_Plane(pln);
    
    math_Matrix M = math_Matrix(1, length, 1, 3);
    math_Vector b = math_Vector(1, length);
    
    for (int i = 1; i <= length; i++) {
        GeomAPI_ProjectPointOnSurf proj = GeomAPI_ProjectPointOnSurf(ocPoints.Value(i), plane);
        Standard_Real u, v;
        proj.Parameters(1, u, v);
        M(i, 1) = u;
        M(i, 2) = v;
        M(i, 3) = 1;
        b(i) = u*u + v*v;
    }
    
    math_GaussLeastSquare gls = math_GaussLeastSquare(M);
    math_Vector x = math_Vector(1,3);
    x(1) = pln.Location().X();
    x(2) = pln.Location().Y();
    x(3) = pln.Location().Z();
    if (gls.IsDone()) {
        gls.Solve(b, x);
    }
    
    Standard_Real ru = x(1) * 0.5;
    Standard_Real rv = x(2) * 0.5;
    //Standard_Real rz = Sqrt(x(3)+rx*rx+ry*ry);
    
    gp_Pnt r = plane->Value(ru, rv);

    SCNVector3 res = {(float)r.X(), (float)r.Y(), (float)r.Z()};
    
    return res;
}

+ (SCNVector3) pc1Of:(const SCNVector3 []) points
            ofLength:(int) length
{
    TColgp_Array1OfPnt ocPoints = [self convertPoints:points ofLength:length];
    gp_Pln pln = [self projectOntoPlane:ocPoints];
    gp_Ax1 axis = pln.Axis();
    gp_Dir dir = axis.Direction();
    
    return {(float)dir.X(), (float)dir.Y(), (float)dir.Z()};
}

+ (gp_Pln) projectOntoPlane:(const TColgp_Array1OfPnt&) ocPoints {
    GProp_PGProps Pmat(ocPoints);
    gp_Pnt g = Pmat.CentreOfMass();
    Standard_Real Xg,Yg,Zg;
    g.Coord(Xg,Yg,Zg);
    GProp_PrincipalProps Pp = Pmat.PrincipalProperties();
    gp_Vec V1 = Pp.FirstAxisOfInertia();
    gp_Pln pln = gp_Pln(g, V1);
    
    return pln;
}

+ (TColgp_Array1OfPnt) convertPoints:(const SCNVector3 []) points
                            ofLength:(int) length
{
    TColgp_Array1OfPnt ocPoints = TColgp_Array1OfPnt(1, length);
    
    for (int i = 1; i <= length; i++) {
        ocPoints.SetValue(i, gp_Pnt(points[i-1].x, points[i-1].y, points[i-1].z));
    }
    
    return ocPoints;
}

+ (int) coincidentDimensionsOf:(const SCNVector3 [])points
                      ofLength:(int)length
{
    TColgp_Array1OfPnt ocPoints = TColgp_Array1OfPnt(1, length);
    
    for (int i = 1; i <= length; i++) {
        ocPoints.SetValue(i, gp_Pnt(points[i-1].x, points[i-1].y, points[i-1].z));
    }
    
    GProp_PEquation eq = GProp_PEquation(ocPoints, flatteningTolerance);
    if (eq.IsPlanar()) {
        return 2;
    } else if (eq.IsLinear()) {
        return 1;
    } else if (eq.IsPoint()) {
        return 0;
    } else {
        return 3;
    }
}

@end

//
//  OCCT.m
//  Loop
//
//  Created by Jan on 25.01.19.
//  Copyright © 2019 Jan. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "OCCT.h"

#include <math_Matrix.hxx>
#include <TopoDS_Shape.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepPrimAPI_MakeSphere.hxx>
#include <BRepMesh_IncrementalMesh.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS.hxx>
#include <Poly.hxx>
#include <NCollection_DataMap.hxx>
#include <TCollection_AsciiString.hxx>
#include <BRepAlgoAPI_Fuse.hxx>
#include <BRepAlgoAPI_Cut.hxx>
#include <BRepAlgoAPI_Common.hxx>
#include <gp_GTrsf.hxx>
#include <BRepBuilderAPI_GTransform.hxx>
#include <BRepBndLib.hxx>
#include <GCPnts_QuasiUniformDeflection.hxx>
#include <BRepAdaptor_Curve.hxx>
#include <BRepOffsetAPI_MakePipe.hxx>
#include <BRepBuilderAPI_MakeFace.hxx>
#include <GProp_PEquation.hxx>
#include <NCollection_Array1.hxx>
#include <GeomAPI_ProjectPointOnSurf.hxx>
#include <GeomAPI_ProjectPointOnCurve.hxx>
#include <Geom_Line.hxx>
#include <Geom_Plane.hxx>
#include <GeomAPI_Interpolate.hxx>
#include <BRepPrimAPI_MakeRevol.hxx>

// For creating the flask (was just a test)
#include <GC_MakeArcOfCircle.hxx>
#include <GC_MakeSegment.hxx>
#include <BRepBuilderAPI_MakeEdge.hxx>
#include <BRepBuilderAPI_MakeWire.hxx>
#include <BRepBuilderAPI_MakeFace.hxx>
#include <BRepPrimAPI_MakePrism.hxx>
#include <BRepBuilderAPI_Transform.hxx>
#include <BRepFilletAPI_MakeFillet.hxx>
#include <BRepPrimAPI_MakeCylinder.hxx>
#include <BRepOffsetAPI_MakeThickSolid.hxx>
#include <Geom_CylindricalSurface.hxx>
#include <Geom2d_Ellipse.hxx>
#include <Geom2d_TrimmedCurve.hxx>
#include <GCE2d_MakeSegment.hxx>
#include <BRepLib.hxx>
#include <BRepOffsetAPI_ThruSections.hxx>


typedef struct {
    float x, y, z;    // position
//    float nx, ny, nz; // normal
} MyVertex;

double meshDeflection = 0.01;
double lineDeflection = 0.0003;
double flatteningTolerance = 0.01;

NSDate *start;

NCollection_DataMap<TCollection_AsciiString, TopoDS_Shape> shapeRegistry = NCollection_DataMap<TCollection_AsciiString, TopoDS_Shape>();
NCollection_DataMap<TCollection_AsciiString, gp_Trsf> transformRegistry = NCollection_DataMap<TCollection_AsciiString, gp_Trsf>();

@implementation OCCT : NSObject

- (TCollection_AsciiString) randomString {
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

- (const char *) toHeapString:(TCollection_AsciiString) input {
    const char *conv = input.ToCString();
    char *res = new char[strlen(conv) + 1];
    std::copy(conv, conv + strlen(conv) + 1, res);
    return res;
}

- (TCollection_AsciiString) storeInRegistry:(TopoDS_Shape &) shape {
    TCollection_AsciiString key = [self randomString];
    shapeRegistry.Bind(key, shape);
    return key;
}

- (void) storeInRegistry:(TopoDS_Shape &) shape
                 withKey:(TCollection_AsciiString) key {
    shapeRegistry.Bind(key, shape);
}

- (void) deleteFromRegistry:(TCollection_AsciiString) key {
    shapeRegistry.UnBind(key);
    transformRegistry.UnBind(key);
}

- (const char *) storeInRegistryWithCString:(TopoDS_Shape &) shape {
    TCollection_AsciiString key = [self randomString];
    shapeRegistry.Bind(key, shape);
    return [self toHeapString:key];
}

- (TopoDS_Shape) retrieveFromRegistry:(TCollection_AsciiString) key {
    return shapeRegistry.Find(key);
}

- (TopoDS_Shape) retrieveFromRegistryWithCString:(const char *) label {
    TCollection_AsciiString key = TCollection_AsciiString(label);
    return [self retrieveFromRegistry:key];
}

- (TopoDS_Shape) retrieveFromRegistryTransformed:(TCollection_AsciiString) key {
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

- (void) freeShape:(const char *) label {
    TopoDS_Shape shape = [self retrieveFromRegistryWithCString:label];
    shape.Nullify();
    TCollection_AsciiString key = TCollection_AsciiString(label);
    [self deleteFromRegistry:key];
}

- (void) setGTransformOf:(const char *) label
                  affine:(SCNMatrix4) affine
             translation:(SCNVector3) translation {
    start = [NSDate date];
    
    TCollection_AsciiString key(label);
    TopoDS_Shape shape = [self retrieveFromRegistry:key];
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
    
    [self deleteFromRegistry:key];
    [self storeInRegistry:newShape withKey:key];
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Transformation took %f", timeInterval);
}

- (void) setTransformOf:(const char *) label
         transformation:(SCNMatrix4) mat {
    TCollection_AsciiString key(label);
    gp_Trsf trans;
    trans.SetValues(mat.m11, mat.m21, mat.m31, mat.m41, mat.m12, mat.m22, mat.m32, mat.m42, mat.m13, mat.m23, mat.m33, mat.m43);
    transformRegistry.Bind(key, trans);
}

- (void) setPivotOf:(const char *) label
              pivot:(SCNMatrix4) mat {
    
    TCollection_AsciiString key = TCollection_AsciiString(label);
    TopoDS_Shape shape = [self retrieveFromRegistry: key];

    gp_Trsf trans;
    trans.SetValues(mat.m11, mat.m21, mat.m31, mat.m41, mat.m12, mat.m22, mat.m32, mat.m42, mat.m13, mat.m23, mat.m33, mat.m43);
    gp_Trsf transInv = trans.Inverted();
    BRepBuilderAPI_Transform trsf(shape, transInv);
    
    TopoDS_Shape newShape = trsf.Shape();
    [self storeInRegistry:newShape withKey:key];
    transformRegistry.Bind(key, trans);
}

- (SCNVector3) center:(const char *) label {
    
    TCollection_AsciiString key = TCollection_AsciiString(label);
    TopoDS_Shape shape = [self retrieveFromRegistry: key];
    
    start = [NSDate date];
    
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
    
    [self storeInRegistry:newShape withKey:key];
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Centering took %f", timeInterval);
    
    return newCenter;
}

- (const SCNVector3 *) flattened:(const SCNVector3 []) points
                        ofLength:(int) length
{
    TColgp_Array1OfPnt ocPoints = TColgp_Array1OfPnt(1, length);
    
    for (int i = 1; i <= length; i++) {
        ocPoints.SetValue(i, gp_Pnt(points[i-1].x, points[i-1].y, points[i-1].z));
    }
    
    GProp_PEquation eq = GProp_PEquation(ocPoints, flatteningTolerance);
    if (eq.IsPlanar()) {
        Handle(Geom_Plane) plane = new Geom_Plane(eq.Plane());
        for (int i = 1; i <= length; i++) {
            GeomAPI_ProjectPointOnSurf proj = GeomAPI_ProjectPointOnSurf(ocPoints.Value(i), plane);
            ocPoints.SetValue(i, proj.Point(1));
        }
    } else if (eq.IsLinear()) {
        Handle(Geom_Line) line = new Geom_Line(eq.Line());
        for (int i = 1; i <= length; i++) {
            GeomAPI_ProjectPointOnCurve proj = GeomAPI_ProjectPointOnCurve(ocPoints.Value(i), line);
            ocPoints.SetValue(i, proj.Point(1));
        }
    } else if (eq.IsPoint()) {
        for (int i = 1; i <= length; i++) {
            ocPoints.SetValue(i, eq.Point());
        }
    }
    
    SCNVector3 *res = new SCNVector3[length];
    for (int i = 1; i <= length; i++) {
        gp_Pnt pt = ocPoints.Value(i);
        res[i-1] = {(float)pt.X(), (float)pt.Y(), (float)pt.Z()};
    }
    
    return res;
}

- (int) coincidentDimensionsOf:(const SCNVector3 [])points
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

- (void) someMethod {
    NSLog(@"SomeMethod Ran");
    
    math_Matrix mat = math_Matrix(0, 2, 0, 2);
    mat(0,0) = 0;
    mat(0,1) = 0;
    mat(0,2) = 1.0;
    mat(1,0) = 1;
    mat(1,1) = 1;
    mat(1,2) = 1.0;
    mat(2,0) = 0;
    mat(2,1) = 1;
    mat(2,2) = 1.0;
    
    double area = 0.5 * mat.Determinant();
    NSLog(@"%f", area);
    
    TCollection_AsciiString rand = [self randomString];
    NSLog(@"%s", rand.ToCString());
}

- (const char *) createCube
{
    start = [NSDate date];
    
    TopoDS_Shape aCube = BRepPrimAPI_MakeBox(5, 5, 5);
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Creation took %f", timeInterval);
    
    double linearDeflection = 0.01;
    [self triangulate:aCube withDeflection:linearDeflection];
    
    TopoDS_Shape aSphere = BRepPrimAPI_MakeSphere(1);
    gp_Trsf move;
    move.SetTranslation(gp_Vec(1.2, 0, 3));
    BRepBuilderAPI_Transform trsf(aSphere, move);
    start = [NSDate date];
    TopoDS_Shape bRes = BRepAlgoAPI_Fuse(aCube, trsf.Shape());
    
    timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Subtraction took %f", timeInterval);

    
    TCollection_AsciiString key = [self storeInRegistry:bRes];
    return [self toHeapString:key];
}

- (const char *) createBox:(double) width
                    height:(double) height
                    length:(double) length
{
    start = [NSDate date];
    
    NSLog(@"box height: %f", height);
    
    gp_Pnt corner = gp_Pnt(-width/2, -height/2, -length/2);
    TopoDS_Shape aBox = BRepPrimAPI_MakeBox(corner, width, height, length);
    TCollection_AsciiString key = [self storeInRegistry:aBox];
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Box creation took %f", timeInterval);
    
    return [self toHeapString:key];
}

- (const char *) createPath:(const SCNVector3 []) points
                     length:(int) length
                    corners:(const int []) corners
                     closed:(bool) closed
{
    start = [NSDate date];
    BRepBuilderAPI_MakeWire makeWire;
    
    TColgp_SequenceOfPnt curvePoints;
    
    int startAt = 0;
    bool onlyRoundCorners = true;
    
    if (closed) {
        /// A little trick to make curvature continuity at the start/endpoint easier:
        /// Find out if the path consists purely of round corners. In that case OCCT can handle this for us.
        /// Otherwise, choose a sharp corner to start with, so that there is no round corner at the seam.
        for (int i = 0; i < length; i++) {
            if (corners[i] == 1) {
                onlyRoundCorners = false;
                startAt = i;
                break;
            }
        }
    }
    
    /// If the path is closed and there is a sharp corner at the seam, we need to make one additional step to add the closing edge.
    /// Remember that we always start/end at a sharp corner if there is one.
    int overshoot = (closed && !onlyRoundCorners) ? 1 : 0;

    bool curveMode = false;
    for (int i = 1; i < length + overshoot; i++) {
        
        int ci = (startAt + i) % length;
        int pi = (startAt + i-1) % length;
        gp_Pnt currPoint(points[ci].x, points[ci].y, points[ci].z);
        gp_Pnt prevPoint(points[pi].x, points[pi].y, points[pi].z);
        int currCorner = corners[ci];
        int prevCorner = corners[pi];

        if (currCorner == 1 && prevCorner == 1) {
            if (!prevPoint.IsEqual(currPoint, 0.0001)) {
                TopoDS_Edge edge = BRepBuilderAPI_MakeEdge(prevPoint, currPoint);
                makeWire.Add(edge);
            }
        }
        
        // A curve has started
        if (!curveMode && (prevCorner == 2 || currCorner == 2)) {
            curvePoints = TColgp_SequenceOfPnt();
            curvePoints.Append(prevPoint);
            curveMode = true;
        }
        
        // A curve continues
        if (curveMode) {
            curvePoints.Append(currPoint);
        }
        
        // A curve has ended
        if (curveMode && (currCorner != 2 || i == length+overshoot-1)) {
            curveMode = false;
            
            int segmentLength = curvePoints.Length();
            Handle(TColgp_HArray1OfPnt) segmentPoints = new TColgp_HArray1OfPnt(1, segmentLength);
            TColgp_SequenceOfPnt::Iterator iter = TColgp_SequenceOfPnt::Iterator(curvePoints);
            int j = 1;
            for (; iter.More(); iter.Next()) {
                segmentPoints->SetValue(j++, iter.Value());
            }
            
            try {
                OCC_CATCH_SIGNALS
                
                GeomAPI_Interpolate interpolate = GeomAPI_Interpolate(segmentPoints, closed && onlyRoundCorners, 0.005);
                interpolate.Perform();
                Handle(Geom_BSplineCurve) curve = interpolate.Curve();
                BRepBuilderAPI_MakeEdge makeEdge = BRepBuilderAPI_MakeEdge(curve);
                TopoDS_Edge edge = makeEdge.Edge();
                makeWire.Add(edge);
            } catch (...) {
                
            }
        }
    }
    
    TopoDS_Wire wire;
    
    try {
        OCC_CATCH_SIGNALS
        wire = makeWire.Wire();
    } catch (...) {
        wire = TopoDS_Wire();
    }

    TCollection_AsciiString key = [self storeInRegistry:wire];
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Path creation took %f", timeInterval);
    
    return [self toHeapString:key];
}

- (const char *) createSphere:(double) radius
{
    start = [NSDate date];
    
    TopoDS_Shape aSphere = BRepPrimAPI_MakeSphere(radius);
    TCollection_AsciiString key = [self storeInRegistry:aSphere];
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Sphere creation took %f", timeInterval);
    
    return [self toHeapString:key];
}

- (const char *) createFlask
{
    start = [NSDate date];

    const Standard_Real myWidth = 3;
    const Standard_Real myHeight = 5;
    const Standard_Real myThickness = 2;
    
    // Profile : Define Support Points
    gp_Pnt aPnt1(-myWidth / 2., 0, 0);
    gp_Pnt aPnt2(-myWidth / 2., -myThickness / 4., 0);
    gp_Pnt aPnt3(0, -myThickness / 2., 0);
    gp_Pnt aPnt4(myWidth / 2., -myThickness / 4., 0);
    gp_Pnt aPnt5(myWidth / 2., 0, 0);
    // Profile : Define the Geometry
    Handle(Geom_TrimmedCurve) anArcOfCircle = GC_MakeArcOfCircle(aPnt2,aPnt3,aPnt4);
    Handle(Geom_TrimmedCurve) aSegment1 = GC_MakeSegment(aPnt1, aPnt2);
    Handle(Geom_TrimmedCurve) aSegment2 = GC_MakeSegment(aPnt4, aPnt5);
    // Profile : Define the Topology
    TopoDS_Edge anEdge1 = BRepBuilderAPI_MakeEdge(aSegment1);
    TopoDS_Edge anEdge2 = BRepBuilderAPI_MakeEdge(anArcOfCircle);
    TopoDS_Edge anEdge3 = BRepBuilderAPI_MakeEdge(aSegment2);
    TopoDS_Wire aWire  = BRepBuilderAPI_MakeWire(anEdge1, anEdge2, anEdge3);
    // Complete Profile
    gp_Ax1 xAxis = gp::OX();
    gp_Trsf aTrsf;
    aTrsf.SetMirror(xAxis);
    BRepBuilderAPI_Transform aBRepTrsf(aWire, aTrsf);
    TopoDS_Shape aMirroredShape = aBRepTrsf.Shape();
    TopoDS_Wire aMirroredWire = TopoDS::Wire(aMirroredShape);
    BRepBuilderAPI_MakeWire mkWire;
    mkWire.Add(aWire);
    mkWire.Add(aMirroredWire);
    TopoDS_Wire myWireProfile = mkWire.Wire();
    // Body : Prism the Profile
    TopoDS_Face myFaceProfile = BRepBuilderAPI_MakeFace(myWireProfile);
    gp_Vec aPrismVec(0, 0, myHeight);
    TopoDS_Shape myBody = BRepPrimAPI_MakePrism(myFaceProfile, aPrismVec);
    // Body : Apply Fillets
    BRepFilletAPI_MakeFillet mkFillet(myBody);
    TopExp_Explorer anEdgeExplorer(myBody, TopAbs_EDGE);
    while(anEdgeExplorer.More()){
        TopoDS_Edge anEdge = TopoDS::Edge(anEdgeExplorer.Current());
        //Add edge to fillet algorithm
        mkFillet.Add(myThickness / 12., anEdge);
        anEdgeExplorer.Next();
    }
    myBody = mkFillet.Shape();
    // Body : Add the Neck
    gp_Pnt neckLocation(0, 0, myHeight);
    gp_Dir neckAxis = gp::DZ();
    gp_Ax2 neckAx2(neckLocation, neckAxis);
    Standard_Real myNeckRadius = myThickness / 4.;
    Standard_Real myNeckHeight = myHeight / 10.;
    BRepPrimAPI_MakeCylinder MKCylinder(neckAx2, myNeckRadius, myNeckHeight);
    TopoDS_Shape myNeck = MKCylinder.Shape();
    myBody = BRepAlgoAPI_Fuse(myBody, myNeck);
    // Body : Create a Hollowed Solid
    TopoDS_Face   faceToRemove;
    Standard_Real zMax = -1;
    for(TopExp_Explorer aFaceExplorer(myBody, TopAbs_FACE); aFaceExplorer.More(); aFaceExplorer.Next()){
        TopoDS_Face aFace = TopoDS::Face(aFaceExplorer.Current());
        // Check if <aFace> is the top face of the bottle's neck
        Handle(Geom_Surface) aSurface = BRep_Tool::Surface(aFace);
        if(aSurface->DynamicType() == STANDARD_TYPE(Geom_Plane)){
            Handle(Geom_Plane) aPlane = Handle(Geom_Plane)::DownCast(aSurface);
            gp_Pnt aPnt = aPlane->Location();
            Standard_Real aZ   = aPnt.Z();
            if(aZ > zMax){
                zMax = aZ;
                faceToRemove = aFace;
            }
        }
    }
    TopTools_ListOfShape facesToRemove;
    facesToRemove.Append(faceToRemove);
    BRepOffsetAPI_MakeThickSolid BodyMaker;
    BodyMaker.MakeThickSolidByJoin(myBody, facesToRemove, -myThickness / 50, 0.003);
    // myBody = BodyMaker.Shape();
    // Threading : Create Surfaces
    Handle(Geom_CylindricalSurface) aCyl1 = new Geom_CylindricalSurface(neckAx2, myNeckRadius * 0.99);
    Handle(Geom_CylindricalSurface) aCyl2 = new Geom_CylindricalSurface(neckAx2, myNeckRadius * 1.05);
    // Threading : Define 2D Curves
    gp_Pnt2d aPnt(2. * M_PI, myNeckHeight / 2.);
    gp_Dir2d aDir(2. * M_PI, myNeckHeight / 4.);
    gp_Ax2d anAx2d(aPnt, aDir);
    Standard_Real aMajor = 2. * M_PI;
    Standard_Real aMinor = myNeckHeight / 10;
    Handle(Geom2d_Ellipse) anEllipse1 = new Geom2d_Ellipse(anAx2d, aMajor, aMinor);
    Handle(Geom2d_Ellipse) anEllipse2 = new Geom2d_Ellipse(anAx2d, aMajor, aMinor / 4);
    Handle(Geom2d_TrimmedCurve) anArc1 = new Geom2d_TrimmedCurve(anEllipse1, 0, M_PI);
    Handle(Geom2d_TrimmedCurve) anArc2 = new Geom2d_TrimmedCurve(anEllipse2, 0, M_PI);
    gp_Pnt2d anEllipsePnt1 = anEllipse1->Value(0);
    gp_Pnt2d anEllipsePnt2 = anEllipse1->Value(M_PI);
    Handle(Geom2d_TrimmedCurve) aSegment = GCE2d_MakeSegment(anEllipsePnt1, anEllipsePnt2);
    // Threading : Build Edges and Wires
    TopoDS_Edge anEdge1OnSurf1 = BRepBuilderAPI_MakeEdge(anArc1, aCyl1);
    TopoDS_Edge anEdge2OnSurf1 = BRepBuilderAPI_MakeEdge(aSegment, aCyl1);
    TopoDS_Edge anEdge1OnSurf2 = BRepBuilderAPI_MakeEdge(anArc2, aCyl2);
    TopoDS_Edge anEdge2OnSurf2 = BRepBuilderAPI_MakeEdge(aSegment, aCyl2);
    TopoDS_Wire threadingWire1 = BRepBuilderAPI_MakeWire(anEdge1OnSurf1, anEdge2OnSurf1);
    TopoDS_Wire threadingWire2 = BRepBuilderAPI_MakeWire(anEdge1OnSurf2, anEdge2OnSurf2);
    BRepLib::BuildCurves3d(threadingWire1);
    BRepLib::BuildCurves3d(threadingWire2);
    // Create Threading
    BRepOffsetAPI_ThruSections aTool(Standard_True);
    aTool.AddWire(threadingWire1);
    aTool.AddWire(threadingWire2);
    aTool.CheckCompatibility(Standard_False);
    TopoDS_Shape myThreading = aTool.Shape();
    // Building the Resulting Compound
    TopoDS_Compound aRes;
    BRep_Builder aBuilder;
    aBuilder.MakeCompound (aRes);
    aBuilder.Add (aRes, myBody);
    aBuilder.Add (aRes, myThreading);
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Creation took %f", timeInterval);
    
    [self triangulate:aRes withDeflection:meshDeflection];
    

    TopoDS_Shape aSphere = BRepPrimAPI_MakeSphere(1);
    gp_Trsf move;
    move.SetTranslation(gp_Vec(0, 1, 3));
//    BRepBuilderAPI_Transform trsf(aSphere, move);
    aSphere.Location(TopLoc_Location(move));
    start = [NSDate date];
    TopoDS_Shape bRes = BRepAlgoAPI_Cut(aRes, aSphere);
    
    timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Subtraction took %f", timeInterval);

    TCollection_AsciiString key = [self storeInRegistry:bRes];
    return [self toHeapString:key];
}

- (const char *) sweep:(const char *) profile
                 along:(const char *) path;
{
    start = [NSDate date];
    
    TCollection_AsciiString keyProfile = TCollection_AsciiString(profile);
    TCollection_AsciiString keyPath = TCollection_AsciiString(path);
    
    TopoDS_Shape shapeProfile = [self retrieveFromRegistryTransformed: keyProfile];
    TopoDS_Shape shapePath = [self retrieveFromRegistryTransformed: keyPath];
    
    TopoDS_Face profileFace = BRepBuilderAPI_MakeFace(TopoDS::Wire(shapeProfile));
    
    TopoDS_Shape solid = BRepOffsetAPI_MakePipe(TopoDS::Wire(shapePath), profileFace);

    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Sweeping took %f", timeInterval);
    
    return [self storeInRegistryWithCString:solid];
}

- (const char *) revolve:(const char *) profile
              aroundAxis:(SCNVector3) axisPosition
           withDirection:(SCNVector3) axisDirection
{
    start = [NSDate date];
    
    TCollection_AsciiString keyProfile = TCollection_AsciiString(profile);
    
    TopoDS_Shape shapeProfile = [self retrieveFromRegistryTransformed: keyProfile];
    
    gp_Ax1 axis = gp_Ax1(gp_Pnt(axisPosition.x, axisPosition.y, axisPosition.z),
                         gp_Dir(axisDirection.x, axisDirection.y, axisDirection.z));
    
    TopoDS_Shape solid = BRepPrimAPI_MakeRevol(shapeProfile, axis);
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Sweeping took %f", timeInterval);
    
    return [self storeInRegistryWithCString:solid];
    
}

- (const char *) booleanCut:(const char *) a
                   subtract:(const char *) b;
{
    start = [NSDate date];
    
    TCollection_AsciiString keyA = TCollection_AsciiString(a);
    TCollection_AsciiString keyB = TCollection_AsciiString(b);
    
    TopoDS_Shape shapeA = [self retrieveFromRegistryTransformed: keyA];
    TopoDS_Shape shapeB = [self retrieveFromRegistryTransformed: keyB];

    TopoDS_Shape difference = BRepAlgoAPI_Cut(shapeA, shapeB);
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Boolean cut took %f", timeInterval);
    
    return [self storeInRegistryWithCString:difference];
}


- (const char *) booleanJoin:(const char *) a
                        with:(const char *) b
{
    TCollection_AsciiString keyA = TCollection_AsciiString(a);
    TCollection_AsciiString keyB = TCollection_AsciiString(b);
    
    TopoDS_Shape shapeA = [self retrieveFromRegistryTransformed: keyA];
    TopoDS_Shape shapeB = [self retrieveFromRegistryTransformed: keyB];
    
    TopoDS_Shape sum = BRepAlgoAPI_Fuse(shapeA, shapeB);
    
    return [self storeInRegistryWithCString:sum];
}

- (const char *) booleanIntersect:(const char *) a
                             with:(const char *) b
{
    start = [NSDate date];
    
    TCollection_AsciiString keyA = TCollection_AsciiString(a);
    TCollection_AsciiString keyB = TCollection_AsciiString(b);
    
    TopoDS_Shape shapeA = [self retrieveFromRegistryTransformed: keyA];
    TopoDS_Shape shapeB = [self retrieveFromRegistryTransformed: keyB];
    
    TopoDS_Shape sum = BRepAlgoAPI_Common(shapeA, shapeB);
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Boolean intersect took %f", timeInterval);
    
    return [self storeInRegistryWithCString:sum];
}


- (SCNGeometry *) sceneKitMeshOf:(const char *)label {
    TCollection_AsciiString key = TCollection_AsciiString(label);
    TopoDS_Shape shape = [self retrieveFromRegistry:key];
    return [self triangulate:shape withDeflection:meshDeflection];
}

- (SCNGeometry *) sceneKitLinesOf:(const char *)label {
    TCollection_AsciiString key = TCollection_AsciiString(label);
    TopoDS_Shape shape = [self retrieveFromRegistry:key];
    return [self getEdges:shape withDeflection:lineDeflection];
}

- (SCNGeometry *) sceneKitTubesOf:(const char *)label {
    TCollection_AsciiString key = TCollection_AsciiString(label);
    TopoDS_Shape shape = [self retrieveFromRegistry:key];
    return [self getTube:shape withDeflection:lineDeflection];
}

- (SCNGeometry *) getTube:(TopoDS_Shape &)shape
           withDeflection:(const Standard_Real)deflection
{
    const float radius = 0.0005;
    const int sides = 3;
    
    int noOfNodes = 0;
    int noOfSegments = 0;
    
    for (TopExp_Explorer exEdge(shape, TopAbs_EDGE); exEdge.More(); exEdge.Next())
    {
        BRepAdaptor_Curve curveAdaptor;
        curveAdaptor.Initialize(TopoDS::Edge(exEdge.Current()));
        
        GCPnts_QuasiUniformDeflection uniformAbscissa;
        uniformAbscissa.Initialize(curveAdaptor, deflection);
        
        if(uniformAbscissa.IsDone())
        {
            Standard_Integer nbr = uniformAbscissa.NbPoints();
            noOfNodes += nbr;
            noOfSegments += nbr - 1;
        }
    }
    
    int noOfVertices = noOfSegments*((sides+1)*2);
    int noOfTriangles = noOfSegments * sides * 2;
    SCNVector3 vertices[noOfVertices];
    SCNVector3 normals[noOfVertices];
    int indices[noOfTriangles * 3];
    
    int vertexIndex = 0;
    int triIndex = 0;
    for (TopExp_Explorer exEdge(shape, TopAbs_EDGE); exEdge.More(); exEdge.Next())
    {
        BRepAdaptor_Curve curveAdaptor;
        curveAdaptor.Initialize(TopoDS::Edge(exEdge.Current()));
        
        GCPnts_QuasiUniformDeflection uniformAbscissa;
        uniformAbscissa.Initialize(curveAdaptor, deflection);
        
        if(uniformAbscissa.IsDone())
        {
            Standard_Integer nbr = uniformAbscissa.NbPoints();
            gp_Pnt prev;
            for ( Standard_Integer i = 1 ; i <= nbr ; i++ )
            {
                gp_Pnt pt = curveAdaptor.Value(uniformAbscissa.Parameter(i));
                
                if (i >= 2) {
                    // Create cyllinder
                    gp_Vec vec = gp_Vec(prev, pt).Normalized();
                    gp_Vec notParallel = gp_Vec(1, 0, 0);
                    if (abs(notParallel.Dot(vec)) >= 0.99) {
                        notParallel = gp_Vec(0, 1, 0);
                    }
                    gp_Vec perpendicular = vec.Crossed(notParallel).Normalized();
                    gp_Ax1 rotationAxis = gp_Ax1(pt, gp_Dir(vec));
                    
                    for (int j = 0; j <= sides; j++) {
                        float rotation = (M_PI*2) * (((float)j) / sides);
                        gp_Vec dir = perpendicular.Rotated(rotationAxis, rotation);
                        gp_Vec offset = dir.Scaled(radius);
                        gp_Pnt v1 = prev.Translated(offset);
                        gp_Pnt v2 =   pt.Translated(offset);
                        vertices[vertexIndex]  = {(float)v1.X(), (float)v1.Y(), (float)v1.Z()};
                        vertices[vertexIndex+1]= {(float)v2.X(), (float)v2.Y(), (float)v2.Z()};
                        normals[vertexIndex]   = {(float)dir.X(), (float)dir.Y(), (float)dir.Z()};
                        normals[vertexIndex+1] = {(float)dir.X(), (float)dir.Y(), (float)dir.Z()};
                        if (j >= 1) {
                            indices[(triIndex*3)+0] = vertexIndex;
                            indices[(triIndex*3)+1] = vertexIndex+1;
                            indices[(triIndex*3)+2] = vertexIndex-1;
                            triIndex ++;
                            indices[(triIndex*3)+0] = vertexIndex-1;
                            indices[(triIndex*3)+1] = vertexIndex-2;
                            indices[(triIndex*3)+2] = vertexIndex;
                            triIndex ++;
                        }
                        vertexIndex += 2;
                    }
                }
                prev = pt;
            }
        }
    }
    
    SCNGeometry *geometry = [self convertToSCNMesh:vertices withNormals:normals withIndices:indices vertexCount:noOfVertices primitiveCount:noOfTriangles];
    return geometry;
}

- (SCNGeometry *) getEdges:(TopoDS_Shape &)shape
            withDeflection:(const Standard_Real)deflection
{
    int noOfNodes = 0;
    int noOfSegments = 0;
    
    for (TopExp_Explorer exEdge(shape, TopAbs_EDGE); exEdge.More(); exEdge.Next())
    {
        BRepAdaptor_Curve curveAdaptor;
        curveAdaptor.Initialize(TopoDS::Edge(exEdge.Current()));
        
        GCPnts_QuasiUniformDeflection uniformAbscissa;
        uniformAbscissa.Initialize(curveAdaptor, deflection);
        
        if(uniformAbscissa.IsDone())
        {
            Standard_Integer nbr = uniformAbscissa.NbPoints();
            noOfNodes += nbr;
            noOfSegments += nbr - 1;
        }
    }
    
    SCNVector3 vertices[noOfNodes];
    int indices[noOfSegments * 2];
    
    int vertexIndex = 0;
    int segmentIndex = 0;
    for (TopExp_Explorer exEdge(shape, TopAbs_EDGE); exEdge.More(); exEdge.Next())
    {
        BRepAdaptor_Curve curveAdaptor;
        curveAdaptor.Initialize(TopoDS::Edge(exEdge.Current()));
        
        GCPnts_QuasiUniformDeflection uniformAbscissa;
        uniformAbscissa.Initialize(curveAdaptor, deflection);
        
        if(uniformAbscissa.IsDone())
        {
            Standard_Integer nbr = uniformAbscissa.NbPoints();
            for ( Standard_Integer i = 1 ; i <= nbr ; i++ )
            {
                gp_Pnt pt = curveAdaptor.Value(uniformAbscissa.Parameter(i));
                vertices[vertexIndex] = {(float) pt.X(), (float) pt.Y(), (float) pt.Z()};
                
                if (i >= 2) {
                    indices[segmentIndex++] = vertexIndex-1;
                    indices[segmentIndex++] = vertexIndex;
                }
                
                vertexIndex ++;
            }
        }
    }
    
    SCNGeometry *geometry = [self convertToSCNLines:vertices withIndices:indices vertexCount:noOfNodes primitiveCount:noOfSegments];
    return geometry;
}

- (SCNGeometry *) convertToSCNLines:(nonnull const SCNVector3 *)vertices
                        withIndices:(nonnull const int *)indices
                        vertexCount:(int)noOfVertices
                     primitiveCount:(int)noOfPrimitives
{
    start = [NSDate date];
    
    SCNGeometrySource *vertexSource =
    vertexSource = [SCNGeometrySource geometrySourceWithVertices:vertices count:noOfVertices];
    
    NSData *indexData = [NSData dataWithBytes:indices length:sizeof(int) * noOfPrimitives * 2];
    SCNGeometryElement *element =
    [SCNGeometryElement geometryElementWithData:indexData
                                  primitiveType:SCNGeometryPrimitiveTypeLine
                                 primitiveCount:noOfPrimitives
                                  bytesPerIndex:sizeof(int)];
    
    SCNGeometry *geometry;
    
    geometry = [SCNGeometry geometryWithSources:@[vertexSource]
                                       elements:@[element]];
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Conversion took %f", timeInterval);
    
    return geometry;
}


/// Inspired by https://github.com/openscenegraph/OpenSceneGraph/blob/master/src/osgPlugins/OpenCASCADE/ReaderWriterOpenCASCADE.cpp and StlAPI_Writer.cxx of OCCT Source
- (SCNGeometry *) triangulate:(TopoDS_Shape &)shape
               withDeflection:(const Standard_Real)deflection
{
    start = [NSDate date];
    /// Update the incremental mesh
    BRepMesh_IncrementalMesh mesh(shape, deflection);

    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Incremental mesh took %f", timeInterval);
    start = [NSDate date];

    
    /// First count the required nodes and triangles
    int noOfNodes = 0;
    int noOfTriangles = 0;
    
    /// Iterate through the faces. BRepMesh_IncrementalMesh does not create a triangulation for the
    /// entire object, but rather associates one with each face.
    for (TopExp_Explorer ex(shape, TopAbs_FACE); ex.More(); ex.Next())
    {
        TopLoc_Location aLoc;
        /// This method does not calculate a triangulation. It simply reads out the one calculated when calling BRepMesh_IncrementalMesh. Therefore this loop is fast.
        Handle(Poly_Triangulation) aTriangulation = BRep_Tool::Triangulation(TopoDS::Face (ex.Current()), aLoc);
        if (!aTriangulation.IsNull())
        {
            noOfNodes += aTriangulation->NbNodes();
            noOfTriangles += aTriangulation->NbTriangles();
        }
    }
    
    NSLog(@"Shape has %d vertices", noOfNodes);
    NSLog(@"Shape has %d triangles", noOfTriangles);
    

    SCNVector3 vertices[noOfNodes];
    SCNVector3 normals[noOfNodes];
    int indices[noOfTriangles * 3];
    
    int vertexIndex = 0;
    int triangleIndex = 0;
    /// Now loop over the faces again, populating the arrays
    for (TopExp_Explorer ex(shape, TopAbs_FACE); ex.More(); ex.Next())
    {
        TopoDS_Face face = TopoDS::Face(ex.Current());
        
        TopLoc_Location location;
        /// Triangulate current face
        Handle (Poly_Triangulation) triangulation = BRep_Tool::Triangulation(face, location);
        Poly::ComputeNormals(triangulation);
        gp_Trsf transformation = location.Transformation();
        if (!triangulation.IsNull())
        {
            /// Populate vertex and normal array
            int noOfNodes = triangulation->NbNodes();
            const TColgp_Array1OfPnt& nodes = triangulation->Nodes();
            for (Standard_Integer i = nodes.Lower(); i <= nodes.Upper(); ++i)
            {
                gp_Pnt pt = nodes(i);
                pt.Transform(transformation);
                
                gp_Dir normal = triangulation->Normal(i);
                normal.Transform(transformation);
                if (face.Orientation() == TopAbs_REVERSED)
                {
                    normal = normal.Reversed();
                }
                
                /// nodes.Lower() will be 1, because in OCCT Arrays start at 1
                /// In OCCT Z is up, while in SceneKit Y is up, so Z and Y have to be swapped
                vertices[vertexIndex + i - 1] = {(float) pt.X(), (float) pt.Y(), (float) pt.Z()};
                normals[vertexIndex + i - 1] = {(float) normal.X(), (float) normal.Y(), (float) normal.Z()};
            }
            
            /// Populate index array
            const Poly_Array1OfTriangle& triangles = triangulation->Triangles();
            
            Standard_Integer v1, v2, v3;
            for (Standard_Integer i = triangles.Lower(); i <= triangles.Upper(); ++i)
            {
                if (face.Orientation() != TopAbs_REVERSED)
                {
                    triangles(i).Get(v1, v2, v3);
                } else
                {
                    triangles(i).Get(v1, v3, v2);
                }
                
                indices[triangleIndex++] = vertexIndex + v1 - 1;
                indices[triangleIndex++] = vertexIndex + v2 - 1;
                indices[triangleIndex++] = vertexIndex + v3 - 1;
            }
            
            vertexIndex += noOfNodes;
        }
    }
    
    timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Meshification took %f", timeInterval);

    SCNGeometry *geometry = [self convertToSCNMesh:vertices withNormals:normals withIndices:indices vertexCount:noOfNodes primitiveCount:noOfTriangles];    
    
    return geometry;
}

/// Inspired by https://github.com/matthewreagan/TerrainMesh3D/blob/master/TerrainMesh3D/TerrainMesh.m
- (SCNGeometry *) convertToSCNMesh:(nonnull const SCNVector3 *)vertices
                       withNormals:(nonnull const SCNVector3 *)normals
                       withIndices:(nonnull const int *)indices
                       vertexCount:(int)noOfVertices
                    primitiveCount:(int)noOfPrimitives
{
    start = [NSDate date];
    
    SCNGeometrySource *vertexSource =
    vertexSource = [SCNGeometrySource geometrySourceWithVertices:vertices count:noOfVertices];
    
    SCNGeometrySource *normalSource =
    normalSource = [SCNGeometrySource geometrySourceWithNormals:normals count:noOfVertices];
    
    NSData *indexData = [NSData dataWithBytes:indices length:sizeof(int) * noOfPrimitives * 3];
    SCNGeometryElement *element =
    [SCNGeometryElement geometryElementWithData:indexData
                                  primitiveType:SCNGeometryPrimitiveTypeTriangles
                                 primitiveCount:noOfPrimitives
                                  bytesPerIndex:sizeof(int)];
    
    SCNGeometry *geometry;
    
    geometry = [SCNGeometry geometryWithSources:@[vertexSource, normalSource]
                                       elements:@[element]];
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"Conversion took %f", timeInterval);
    
    return geometry;
}

@end

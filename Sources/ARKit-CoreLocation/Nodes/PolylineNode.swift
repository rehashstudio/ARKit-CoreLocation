//
//  PolylineNode.swift
//  ARKit+CoreLocation
//
//  Created by Ilya Seliverstov on 11/08/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import SceneKit
import MapKit

/// A block that will build an SCNBox with the provided distance.
/// Note: the distance should be assigned to the length
public typealias BoxBuilder = (_ distance: CGFloat) -> SCNBox

/// A Node that is used to show directions in AR-CL.
public class PolylineNode: LocationNode {
    public var locationNodes = [LocationNode]()

    public let polyline: MKPolyline
    public let altitude: CLLocationDistance
    public let boxBuilder: BoxBuilder

    /// Creates a `PolylineNode` from the provided polyline, altitude (which is assumed to be uniform
    /// for all of the points) and an optional SCNBox to use as a prototype for the location boxes.
    ///
    /// - Parameters:
    ///   - polyline: The polyline that we'll be creating location nodes for.
    ///   - altitude: The uniform altitude to use to show the location nodes.
    ///   - tag: a String attribute to identify the node in the scene (e.g when it's touched)
    ///   - boxBuilder: A block that will customize how a box is built.
    public init(polyline: MKPolyline,
                altitude: CLLocationDistance,
                tag: String? = nil,
                boxBuilder: BoxBuilder? = nil,
                locations: [CLLocation] = []) {
        self.polyline = polyline
        self.altitude = altitude
        self.boxBuilder = boxBuilder ?? Constants.defaultBuilder
        
        super.init(location: nil)

        self.tag = tag ?? Constants.defaultTag

        contructNodes(locations)
    }

	required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
	}

}

// MARK: - Implementation

private extension PolylineNode {

    struct Constants {
        static let defaultBuilder: BoxBuilder = { (distance) -> SCNBox in
            let box = SCNBox(width: 1, height: 0.2, length: distance, chamferRadius: 0)
            box.firstMaterial?.diffuse.contents = UIColor(red: 47.0/255.0, green: 125.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            return box
        }
        static let defaultTag: String = ""
    }

    /// This is what actually builds the SCNNodes and appends them to the
    /// locationNodes collection so they can be added to the scene and shown
    /// to the user.  If the prototype box is nil, then the default box will be used
    func contructNodes(_ locations: [CLLocation] = []) {
        if locations.isEmpty {
            let points = polyline.points()
            for i in 0 ..< polyline.pointCount - 1 {
                let a = CLLocation(coordinate: points[i].coordinate, altitude: altitude)
                let b = CLLocation(coordinate: points[i + 1].coordinate, altitude: altitude)
                makeLocationNode(a, b)
            }
        } else {
            for i in 0 ..< locations.count - 1 {
                let a: CLLocation = locations[i]
                let b: CLLocation = locations[i + 1]
                makeLocationNode(a, b)
            }
        }
    }
    
    private func makeLocationNode(_ a: CLLocation,
                                  _ b: CLLocation) {
        let c: CLLocation = a.approxMidpoint(to: b)
        
        let distance = a.distance(from: b)

        let box = boxBuilder(CGFloat(distance))
        let boxNode = SCNNode(geometry: box)
        boxNode.removeFlicker()

        let bearing = -a.bearing(between: b)

        // Orient the line to point from currentLoction to nextLocation
        boxNode.eulerAngles.y = Float(bearing).degreesToRadians

        let locationNode = LocationNode(location: c, tag: tag)
        locationNode.addChildNode(boxNode)

        locationNodes.append(locationNode)
    }

}

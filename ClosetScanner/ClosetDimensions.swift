import Foundation
import RoomPlan
import simd

struct ClosetDimensions {
    let widthMeters: Float
    let depthMeters: Float
    let heightMeters: Float

    var widthInches: Double { Double(widthMeters) * 39.3701 }
    var depthInches: Double { Double(depthMeters) * 39.3701 }
    var heightInches: Double { Double(heightMeters) * 39.3701 }

    var floorAreaSquareFeet: Double {
        (widthInches / 12.0) * (depthInches / 12.0)
    }
}

enum DimensionFormatter {
    /// Formats an inch measurement as feet-inches-fraction, rounded to the
    /// nearest 1/16", e.g. 83.42 -> "6' 11 7/16\""
    static func feetInchesFraction(_ inches: Double) -> String {
        let totalSixteenths = (inches * 16).rounded()
        var wholeInches = Int(totalSixteenths / 16)
        var sixteenths = Int(totalSixteenths) % 16
        if sixteenths < 0 { sixteenths += 16; wholeInches -= 1 }

        let feet = wholeInches / 12
        let remInches = wholeInches % 12

        let fraction = simplifiedFraction(sixteenths, denominator: 16)

        var result = ""
        if feet > 0 { result += "\(feet)' " }
        result += "\(remInches)"
        if let fraction = fraction {
            result += " \(fraction)"
        }
        result += "\""
        return result
    }

    private static func simplifiedFraction(_ numerator: Int, denominator: Int) -> String? {
        guard numerator != 0 else { return nil }
        var n = numerator
        var d = denominator
        let g = gcd(n, d)
        n /= g
        d /= g
        return "\(n)/\(d)"
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var a = a, b = b
        while b != 0 { (a, b) = (b, a % b) }
        return a == 0 ? 1 : a
    }
}

enum RoomDimensionCalculator {
    /// Groups wall lengths into clusters (opposite walls in a rectangular
    /// closet should be near-identical length) and derives width/depth/height.
    /// This is a simplifying assumption appropriate for a standard rectangular
    /// closet; an irregular (L-shaped) closet would need per-wall reporting
    /// instead of a single width x depth figure.
    static func computeDimensions(from room: CapturedRoom) -> ClosetDimensions? {
        let walls = room.walls
        guard !walls.isEmpty else { return nil }

        let lengths = walls.map { $0.dimensions.x }
        let heights = walls.map { $0.dimensions.y }
        let avgHeight = heights.reduce(0, +) / Float(heights.count)

        // Cluster lengths within 5cm of each other.
        var clusters: [[Float]] = []
        for length in lengths.sorted() {
            if let lastIndex = clusters.indices.last,
               let lastValue = clusters[lastIndex].last,
               abs(lastValue - length) < 0.05 {
                clusters[lastIndex].append(length)
            } else {
                clusters.append([length])
            }
        }

        // Sort clusters by total membership (largest groups = the two
        // dominant wall-length pairs in a rectangular room).
        let sortedClusters = clusters.sorted { $0.count > $1.count }
        guard sortedClusters.count >= 1 else { return nil }

        func average(_ values: [Float]) -> Float {
            values.reduce(0, +) / Float(values.count)
        }

        let dimA = average(sortedClusters[0])
        let dimB = sortedClusters.count >= 2 ? average(sortedClusters[1]) : dimA

        let width = max(dimA, dimB)
        let depth = min(dimA, dimB)

        return ClosetDimensions(widthMeters: width, depthMeters: depth, heightMeters: avgHeight)
    }
}

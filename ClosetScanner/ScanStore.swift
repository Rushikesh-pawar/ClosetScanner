import Foundation
import Observation

/// Records the dimensions computed from every completed scan. The Accuracy
/// Test tab can log trials against either the most recent scan or the running
/// average of all recorded scans — averaging N scans of the same closet
/// reduces random sensor noise by roughly sqrt(N) (it cannot remove
/// systematic bias, e.g. a consistent scale error).
@Observable
final class ScanStore {
    private(set) var scans: [ClosetDimensions] = []

    var lastDimensions: ClosetDimensions? { scans.last }

    var averagedDimensions: ClosetDimensions? {
        guard !scans.isEmpty else { return nil }
        let n = Float(scans.count)
        return ClosetDimensions(
            widthMeters: scans.map(\.widthMeters).reduce(0, +) / n,
            depthMeters: scans.map(\.depthMeters).reduce(0, +) / n,
            heightMeters: scans.map(\.heightMeters).reduce(0, +) / n
        )
    }

    func addScan(_ dimensions: ClosetDimensions) {
        scans.append(dimensions)
    }

    /// Call when moving to a different closet — averaging only makes sense
    /// across repeated scans of the same space.
    func clearScans() {
        scans.removeAll()
    }

    /// Max minus min across recorded scans, in inches — a quick visual of
    /// scan-to-scan repeatability for one dimension.
    func spreadInches(of keyPath: KeyPath<ClosetDimensions, Double>) -> Double {
        let values = scans.map { $0[keyPath: keyPath] }
        guard let minValue = values.min(), let maxValue = values.max() else { return 0 }
        return maxValue - minValue
    }
}

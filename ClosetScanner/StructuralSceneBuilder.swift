import SceneKit
import RoomPlan
import simd

enum StructuralSceneBuilder {

    /// Builds a scene showing ONLY the closet's architecture. Note that
    /// `room.objects` (shelves, boxes, clothes, etc. that RoomPlan detected)
    /// is intentionally never read here — that omission is what "removes"
    /// the existing contents from the representation.
    static func buildScene(from room: CapturedRoom) -> SCNScene {
        let scene = SCNScene()
        let rootNode = scene.rootNode

        addSurfaces(room.walls, color: .systemGray4, to: rootNode)
        addSurfaces(room.floors, color: .systemBrown, to: rootNode)
        addSurfaces(room.doors, color: .systemBlue, to: rootNode)
        addSurfaces(room.windows, color: .systemTeal, to: rootNode)
        addSurfaces(room.openings, color: .systemGreen, to: rootNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 500
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        rootNode.addChildNode(ambientNode)

        let directional = SCNLight()
        directional.type = .directional
        directional.intensity = 800
        let directionalNode = SCNNode()
        directionalNode.light = directional
        directionalNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        rootNode.addChildNode(directionalNode)

        return scene
    }

    private static func addSurfaces(_ surfaces: [CapturedRoom.Surface], color: PlatformColor, to rootNode: SCNNode) {
        for surface in surfaces {
            let width = CGFloat(surface.dimensions.x)
            let height = CGFloat(surface.dimensions.y)
            let thickness: CGFloat = 0.05 // visual thickness only, not a measured value

            let box = SCNBox(width: width, height: height, length: thickness, chamferRadius: 0)
            box.firstMaterial?.diffuse.contents = color
            box.firstMaterial?.isDoubleSided = true

            let node = SCNNode(geometry: box)
            node.simdTransform = surface.transform
            rootNode.addChildNode(node)
        }
    }
}

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#endif

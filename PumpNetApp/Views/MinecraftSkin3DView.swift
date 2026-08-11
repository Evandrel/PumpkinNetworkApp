import SceneKit
import SwiftUI
import UIKit

struct MinecraftSkin3DView: UIViewRepresentable {
    let skin: MinecraftSkin

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.antialiasingMode = .multisampling4X
        sceneView.autoenablesDefaultLighting = false
        sceneView.isJitteringEnabled = false

        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.orbitCamera(_:))
        )
        panGesture.maximumNumberOfTouches = 1
        sceneView.addGestureRecognizer(panGesture)

        let resetGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.resetRotation)
        )
        resetGesture.numberOfTapsRequired = 2
        sceneView.addGestureRecognizer(resetGesture)

        context.coordinator.render(skin, in: sceneView)
        sceneView.isAccessibilityElement = true
        sceneView.accessibilityLabel = "3D model of \(skin.username)'s Minecraft skin"
        sceneView.accessibilityHint = "Drag in any direction to orbit. Double-tap to reset."
        return sceneView
    }

    func updateUIView(_ sceneView: SCNView, context: Context) {
        guard context.coordinator.renderedProfileID != skin.profileID else { return }
        context.coordinator.render(skin, in: sceneView)
        sceneView.accessibilityLabel = "3D model of \(skin.username)'s Minecraft skin"
    }

    final class Coordinator: NSObject {
        fileprivate var renderedProfileID: String?
        private weak var cameraOrbit: SCNNode?
        private var orbitAtDragStart = SCNVector3Zero

        fileprivate func render(_ skin: MinecraftSkin, in sceneView: SCNView) {
            let scene = SCNScene()
            scene.background.contents = UIColor.clear

            let camera = SCNCamera()
            camera.fieldOfView = 32
            camera.zNear = 0.1
            camera.zFar = 200

            let cameraNode = SCNNode()
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(0, 0, 59)
            cameraNode.look(at: SCNVector3Zero)

            let orbit = SCNNode()
            orbit.eulerAngles = SCNVector3(-0.08, 0.42, 0)
            orbit.addChildNode(cameraNode)
            scene.rootNode.addChildNode(orbit)

            let root = MinecraftSkinSceneBuilder.makeModel(for: skin)
            root.position.y = -16
            scene.rootNode.addChildNode(root)

            sceneView.scene = scene
            sceneView.pointOfView = cameraNode
            cameraOrbit = orbit
            renderedProfileID = skin.profileID
        }

        @objc fileprivate func orbitCamera(_ gesture: UIPanGestureRecognizer) {
            guard let cameraOrbit, let view = gesture.view else { return }

            switch gesture.state {
            case .began:
                orbitAtDragStart = cameraOrbit.eulerAngles
            case .changed:
                let translation = gesture.translation(in: view)
                let elevation = orbitAtDragStart.x - Float(translation.y) * 0.010
                cameraOrbit.eulerAngles.x = min(max(elevation, -1.25), 1.25)
                cameraOrbit.eulerAngles.y = orbitAtDragStart.y - Float(translation.x) * 0.020
            default:
                break
            }
        }

        @objc fileprivate func resetRotation() {
            guard let cameraOrbit else { return }
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.35
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            cameraOrbit.eulerAngles = SCNVector3(-0.08, 0.42, 0)
            SCNTransaction.commit()
        }
    }
}

private enum MinecraftSkinSceneBuilder {
    private struct PixelRect {
        let x: Int
        let y: Int
        let width: Int
        let height: Int
    }

    private struct FaceMap {
        let front: PixelRect
        let right: PixelRect
        let back: PixelRect
        let left: PixelRect
        let top: PixelRect
        let bottom: PixelRect
    }

    private struct Dimensions {
        let width: CGFloat
        let height: CGFloat
        let depth: CGFloat
    }

    private final class SkinAtlas {
        let image: CGImage
        let isModern: Bool

        init?(data: Data) {
            guard let image = UIImage(data: data)?.cgImage else { return nil }
            self.image = image
            isModern = image.height >= image.width
        }

        func image(in pixelRect: PixelRect) -> UIImage? {
            let scaleX = CGFloat(image.width) / 64
            let scaleY = CGFloat(image.height) / (isModern ? 64 : 32)
            let cropRect = CGRect(
                x: CGFloat(pixelRect.x) * scaleX,
                y: CGFloat(pixelRect.y) * scaleY,
                width: CGFloat(pixelRect.width) * scaleX,
                height: CGFloat(pixelRect.height) * scaleY
            ).integral

            guard
                cropRect.maxX <= CGFloat(image.width),
                cropRect.maxY <= CGFloat(image.height),
                let croppedImage = image.cropping(to: cropRect)
            else {
                return nil
            }

            return UIImage(cgImage: croppedImage, scale: 1, orientation: .up)
        }
    }

    static func makeModel(for skin: MinecraftSkin) -> SCNNode {
        let model = SCNNode()
        guard let atlas = SkinAtlas(data: skin.imageData) else { return model }

        let head = faceMap(
            front: (8, 8, 8, 8), right: (0, 8, 8, 8),
            back: (24, 8, 8, 8), left: (16, 8, 8, 8),
            top: (8, 0, 8, 8), bottom: (16, 0, 8, 8)
        )
        let hat = faceMap(
            front: (40, 8, 8, 8), right: (32, 8, 8, 8),
            back: (56, 8, 8, 8), left: (48, 8, 8, 8),
            top: (40, 0, 8, 8), bottom: (48, 0, 8, 8)
        )
        let torso = faceMap(
            front: (20, 20, 8, 12), right: (16, 20, 4, 12),
            back: (32, 20, 8, 12), left: (28, 20, 4, 12),
            top: (20, 16, 8, 4), bottom: (28, 16, 8, 4)
        )
        let jacket = faceMap(
            front: (20, 36, 8, 12), right: (16, 36, 4, 12),
            back: (32, 36, 8, 12), left: (28, 36, 4, 12),
            top: (20, 32, 8, 4), bottom: (28, 32, 8, 4)
        )

        let armWidth = skin.model == .slim ? 3 : 4
        let rightArm = armMap(x: 40, y: 16, armWidth: armWidth)
        let rightSleeve = armMap(x: 40, y: 32, armWidth: armWidth)
        let leftArm = atlas.isModern
            ? armMap(x: 32, y: 48, armWidth: armWidth)
            : rightArm
        let leftSleeve = atlas.isModern
            ? armMap(x: 48, y: 48, armWidth: armWidth)
            : nil

        let rightLeg = legMap(x: 0, y: 16)
        let rightPants = legMap(x: 0, y: 32)
        let leftLeg = atlas.isModern ? legMap(x: 16, y: 48) : rightLeg
        let leftPants = atlas.isModern ? legMap(x: 0, y: 48) : nil

        addPart(
            to: model, atlas: atlas,
            dimensions: Dimensions(width: 8, height: 8, depth: 8),
            center: SCNVector3(0, 28, 0), base: head, overlay: hat
        )
        addPart(
            to: model, atlas: atlas,
            dimensions: Dimensions(width: 8, height: 12, depth: 4),
            center: SCNVector3(0, 18, 0), base: torso,
            overlay: atlas.isModern ? jacket : nil
        )

        let armOffset = Float(4 + CGFloat(armWidth) / 2)
        let armDimensions = Dimensions(width: CGFloat(armWidth), height: 12, depth: 4)
        addPart(
            to: model, atlas: atlas, dimensions: armDimensions,
            center: SCNVector3(-armOffset, 18, 0), base: rightArm,
            overlay: atlas.isModern ? rightSleeve : nil
        )
        addPart(
            to: model, atlas: atlas, dimensions: armDimensions,
            center: SCNVector3(armOffset, 18, 0), base: leftArm,
            overlay: leftSleeve
        )

        let legDimensions = Dimensions(width: 4, height: 12, depth: 4)
        addPart(
            to: model, atlas: atlas, dimensions: legDimensions,
            center: SCNVector3(-2, 6, 0), base: rightLeg,
            overlay: atlas.isModern ? rightPants : nil
        )
        addPart(
            to: model, atlas: atlas, dimensions: legDimensions,
            center: SCNVector3(2, 6, 0), base: leftLeg,
            overlay: leftPants
        )

        return model
    }

    private static func addPart(
        to model: SCNNode,
        atlas: SkinAtlas,
        dimensions: Dimensions,
        center: SCNVector3,
        base: FaceMap,
        overlay: FaceMap?
    ) {
        let baseNode = cubeNode(dimensions: dimensions, faces: base, atlas: atlas)
        baseNode.position = center
        model.addChildNode(baseNode)

        if let overlay {
            let layerExpansion: CGFloat = 0.5
            let overlayDimensions = Dimensions(
                width: dimensions.width + layerExpansion,
                height: dimensions.height + layerExpansion,
                depth: dimensions.depth + layerExpansion
            )
            let overlayNode = cubeNode(
                dimensions: overlayDimensions,
                faces: overlay,
                atlas: atlas,
                isOverlay: true
            )
            overlayNode.position = center
            model.addChildNode(overlayNode)
        }
    }

    private static func cubeNode(
        dimensions: Dimensions,
        faces: FaceMap,
        atlas: SkinAtlas,
        isOverlay: Bool = false
    ) -> SCNNode {
        let node = SCNNode()
        let halfWidth = Float(dimensions.width / 2)
        let halfHeight = Float(dimensions.height / 2)
        let halfDepth = Float(dimensions.depth / 2)

        node.addChildNode(faceNode(
            width: dimensions.width, height: dimensions.height,
            image: atlas.image(in: faces.front), isOverlay: isOverlay,
            position: SCNVector3(0, 0, halfDepth), rotation: SCNVector3Zero
        ))
        node.addChildNode(faceNode(
            width: dimensions.width, height: dimensions.height,
            image: atlas.image(in: faces.back), isOverlay: isOverlay,
            position: SCNVector3(0, 0, -halfDepth),
            rotation: SCNVector3(0, Float.pi, 0)
        ))
        node.addChildNode(faceNode(
            width: dimensions.depth, height: dimensions.height,
            image: atlas.image(in: faces.right), isOverlay: isOverlay,
            position: SCNVector3(-halfWidth, 0, 0),
            rotation: SCNVector3(0, -Float.pi / 2, 0)
        ))
        node.addChildNode(faceNode(
            width: dimensions.depth, height: dimensions.height,
            image: atlas.image(in: faces.left), isOverlay: isOverlay,
            position: SCNVector3(halfWidth, 0, 0),
            rotation: SCNVector3(0, Float.pi / 2, 0)
        ))
        node.addChildNode(faceNode(
            width: dimensions.width, height: dimensions.depth,
            image: atlas.image(in: faces.top), isOverlay: isOverlay,
            position: SCNVector3(0, halfHeight, 0),
            rotation: SCNVector3(-Float.pi / 2, 0, 0)
        ))
        node.addChildNode(faceNode(
            width: dimensions.width, height: dimensions.depth,
            image: atlas.image(in: faces.bottom), isOverlay: isOverlay,
            position: SCNVector3(0, -halfHeight, 0),
            rotation: SCNVector3(Float.pi / 2, 0, 0)
        ))
        return node
    }

    private static func faceNode(
        width: CGFloat,
        height: CGFloat,
        image: UIImage?,
        isOverlay: Bool,
        position: SCNVector3,
        rotation: SCNVector3
    ) -> SCNNode {
        let plane = SCNPlane(width: width, height: height)
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = image ?? UIColor.clear
        material.diffuse.magnificationFilter = .nearest
        material.diffuse.minificationFilter = .nearest
        material.diffuse.mipFilter = .none
        material.diffuse.wrapS = .clamp
        material.diffuse.wrapT = .clamp
        material.isDoubleSided = false
        if isOverlay {
            material.blendMode = .alpha
            material.transparencyMode = .aOne
            material.writesToDepthBuffer = false
        }
        plane.firstMaterial = material

        let node = SCNNode(geometry: plane)
        node.position = position
        node.eulerAngles = rotation
        node.renderingOrder = isOverlay ? 1 : 0
        return node
    }

    private static func faceMap(
        front: (Int, Int, Int, Int),
        right: (Int, Int, Int, Int),
        back: (Int, Int, Int, Int),
        left: (Int, Int, Int, Int),
        top: (Int, Int, Int, Int),
        bottom: (Int, Int, Int, Int)
    ) -> FaceMap {
        FaceMap(
            front: rect(front), right: rect(right), back: rect(back),
            left: rect(left), top: rect(top), bottom: rect(bottom)
        )
    }

    private static func armMap(x: Int, y: Int, armWidth: Int) -> FaceMap {
        faceMap(
            front: (x + 4, y + 4, armWidth, 12),
            right: (x, y + 4, 4, 12),
            back: (x + 8 + armWidth, y + 4, armWidth, 12),
            left: (x + 4 + armWidth, y + 4, 4, 12),
            top: (x + 4, y, armWidth, 4),
            bottom: (x + 4 + armWidth, y, armWidth, 4)
        )
    }

    private static func legMap(x: Int, y: Int) -> FaceMap {
        faceMap(
            front: (x + 4, y + 4, 4, 12), right: (x, y + 4, 4, 12),
            back: (x + 12, y + 4, 4, 12), left: (x + 8, y + 4, 4, 12),
            top: (x + 4, y, 4, 4), bottom: (x + 8, y, 4, 4)
        )
    }

    private static func rect(_ values: (Int, Int, Int, Int)) -> PixelRect {
        PixelRect(x: values.0, y: values.1, width: values.2, height: values.3)
    }
}

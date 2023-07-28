//
//  ContentView.swift
//  ARTest
//
//  Created by 이재원 on 2023/07/27.
//

import SwiftUI
import SceneKit
import ARKit
import RealityKit

struct ContentView : View {
    @StateObject var scnCoordinator = SCNViewContainer.Coordinator()
    
    var body: some View {
        VStack {
            let container = SCNViewContainer()
            container.edgesIgnoringSafeArea(.all)
            HStack {
                Button(action: {
                    SCNViewContainer.Coordinator.moveNode(direction: .left)
                }) {
                    Text("⬅️")
                }
                Button(action: {
                    SCNViewContainer.Coordinator.moveNode(direction: .right)
                }) {
                    Text("➡️")
                }
                Button(action: {
                    SCNViewContainer.Coordinator.moveNode(direction: .up)
                }) {
                    Text("⬆️")
                }
                Button(action: {
                    SCNViewContainer.Coordinator.moveNode(direction: .down)
                }) {
                    Text("⬇️")
                }
                Button(action: {
                    SCNViewContainer.Coordinator.moveNode(direction: .forward)
                }) {
                    Text("⏭")
                }
                Button(action: {
                    SCNViewContainer.Coordinator.moveNode(direction: .backward)
                }) {
                    Text("⏮")
                }
            }
        }
    }
}

struct SCNViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.scene = SCNScene()
        sceneView.delegate = context.coordinator
        sceneView.autoenablesDefaultLighting = true
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // MARK: 전면 카메라
        if ARFaceTrackingConfiguration.isSupported {
            // Create a new face tracking configuration
            let configuration = ARFaceTrackingConfiguration()
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        } else {
            // MARK: 후면 카메라
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        
        
        // Load .usdz file
        guard let virtualObjectScene = SCNScene(named: "rabbittest.usdz") else { return sceneView }
        
        // MARK: initial size, position, rotating
        virtualObjectScene.rootNode.scale = SCNVector3(0.1, 0.1, 0.1)
        virtualObjectScene.rootNode.position = SCNVector3(0, 0, -0.42)
        //        virtualObjectScene.rootNode.rotation = SCNVector4(0, 1, 0, 3.14)
        
        sceneView.scene.rootNode.addChildNode(virtualObjectScene.rootNode)
        
        context.coordinator.selectedNode = virtualObjectScene.rootNode
        SCNViewContainer.Coordinator.targetNode = virtualObjectScene.rootNode
        
        // Enable user interaction
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didPinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didRotate(_:)))
        sceneView.addGestureRecognizer(rotationGesture)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate, ObservableObject {
        static var targetNode: SCNNode?
        enum MoveDirection {
            case up, down, left, right, forward, backward
        }
        
        @Published var selectedNode: SCNNode?
        
        // MARK: 상하전우좌우 이동!
        static func moveNode(direction: MoveDirection) {
            guard let node = targetNode else { return }
            var translationVector = SCNVector3Zero
            switch direction {
            case .up:
                // MARK: 얼마나 이동시킬 지 숫자로
                translationVector = SCNVector3(0, 0.07, 0)
            case .down:
                translationVector = SCNVector3(0, -0.07, 0)
            case .left:
                translationVector = SCNVector3(-0.07, 0, 0)
            case .right:
                translationVector = SCNVector3(0.07, 0, 0)
            case .forward:
                translationVector = SCNVector3(0, 0, -0.07)
            case .backward:
                translationVector = SCNVector3(0, 0, 0.07)
            }
            node.runAction(SCNAction.move(by: translationVector, duration: 0.05))
        }
        
        // MARK: 키우고 줄이고
        @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
            guard let sceneView = gesture.view as? ARSCNView else { return }
            let pinchLocation = gesture.location(in: sceneView)
            let hitTest = sceneView.hitTest(pinchLocation)
            if !hitTest.isEmpty {
                let results = hitTest.first!
                let node = results.node
                let pinchAction = SCNAction.scale(by: gesture.scale, duration: 0)
                node.runAction(pinchAction)
                gesture.scale = 1.0
            }
        }
        
        // MARK: 돌려돌려
        @objc func didRotate(_ gesture: UIRotationGestureRecognizer) {
            guard let sceneView = gesture.view as? ARSCNView else { return }
            let rotationLocation = gesture.location(in: sceneView)
            let hitTest = sceneView.hitTest(rotationLocation)
            if !hitTest.isEmpty {
                let results = hitTest.first!
                let node = results.node
                let rotationAction = SCNAction.rotate(by: gesture.rotation, around: SCNVector3(0, -1, 0), duration: 0)
                node.runAction(rotationAction)
                gesture.rotation = 0
            }
        }
    }
}

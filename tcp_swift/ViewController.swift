//
//  ViewController.swift
//  tcp_swift
//
//  Created by MacMini on 18/06/2019.
//  Copyright © 2019 MacMini. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, StreamDelegate, ARSCNViewDelegate, ARSessionDelegate {
    @IBOutlet var sceneView: ARSCNView!
    var inputStream: InputStream!
    var outputStream: OutputStream!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNetworkCommunication()
        
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    
    func setupNetworkCommunication() {
        // 1
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        // 2
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           "192.168.10.108" as CFString,
                                           1105,
                                           &readStream,
                                           &writeStream)

        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()

        inputStream.delegate = self
        outputStream.delegate = self

        inputStream.schedule(in: .current, forMode: RunLoop.Mode.common)
        outputStream.schedule(in: .current, forMode: RunLoop.Mode.common)

        inputStream.open()
        outputStream.open()

        joinChat(username: "john")
        joinChat(username: "exit")
        let data = "exit".data(using: .ascii)!
        _ = data.withUnsafeBytes { outputStream.write($0, maxLength: data.count) }
    }
    
    func joinChat(username: String) {
        let data = "iam:\(username)".data(using: .ascii)!
        _ = data.withUnsafeBytes { outputStream.write($0, maxLength: data.count) }
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            print("new message received")
        case Stream.Event.endEncountered:
            print("new message received")
        case Stream.Event.errorOccurred:
            print("error occurred")
        case Stream.Event.hasSpaceAvailable:
            print("has space available")
        default:
            print("some other event...")
            break
        }
    }
    
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//
//        // 3
////        guard let device = sceneView.device else {
////            return nil
////        }
//
//        // 4
////        let faceGeometry = ARSCNFaceGeometry(device: device)
//
//        // 5
////        let node = SCNNode(geometry: faceGeometry)
//
//        // 6
////        node.geometry?.firstMaterial?.fillMode = .lines
//
//        // 7
////        return node
//    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        
        //        labelNode = SKLabelNode(text: "HW");
        //        labelNode!.fontSize = 20
        //        labelNode!.fontName = "San Fransisco"
        //        labelNode!.position = CGPoint(x:100,y:100)
        //        contentNode!.addChildNode(labelNode)
        
        let blendShapes = faceAnchor.blendShapes
        guard let eyeBlinkLeft = blendShapes[.eyeBlinkLeft] as? Float,
            let eyeBlinkRight = blendShapes[.eyeBlinkRight] as? Float,
            let jawOpen = blendShapes[.jawOpen] as? Float
            else { return }
        
//        print(float2data(number: eyeBlinkLeft)!);
            
//        eyeLeftNode.scale.z = 1 - eyeBlinkLeft
//        eyeRightNode.scale.z = 1 - eyeBlinkRight
//        jawNode.position.y = originalJawY - jawHeight * jawOpen
    }

    func float2data(number: Float) -> Data? {
        return String(format: "%.3f", number).data(using: .ascii)!
    }
}


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
    var valsStr: String!
    var connection: Bool!
    var readyWrite: Bool!
    var mutex: pthread_mutex_t  = pthread_mutex_t()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pthread_mutex_init(&mutex, nil)
        setupNetworkCommunication()
        connection = false
        readyWrite = false
//        valsStr = ""
//        var val = NSNumber(0.1)
//        for i in 0...52 {
//            valsStr += float2data(number: val)
//            val = NSNumber(value:0.02 + val.floatValue )
//        }
//        valsStr += "\0\0\0"
//        write2Socket(str: valsStr)
        
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
        
        inputStream.close()
        outputStream.close()
    }

    
    func setupNetworkCommunication() {
        // 1
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        // 2
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           "10.13.13.103" as CFString,
                                           1111,
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
//
//        write2Socket(str: "jogn")
//        joinChat(username: "exit")
//        let data = "exit".data(using: .ascii)!
//        _ = data.withUnsafeBytes { outputStream.write($0, maxLength: data.count) }
    }
    
    func write2Socket(str: String) {
        let data = "\(str)".data(using: .ascii)!
        _ = data.withUnsafeBytes { outputStream.write($0, maxLength: data.count) }
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            print("new message received")
            pthread_mutex_lock(&mutex)
            let bufferSize = 2
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            let readbytes = inputStream.read(buffer, maxLength: bufferSize)
            print("\(readbytes) bytes read")
            if (readbytes == 2) {
                let str = String(cString: buffer)
                print(str)
                if (str == "1") { readyWrite = true }
            }
            pthread_mutex_unlock(&mutex)
            
        case Stream.Event.endEncountered:
            print("new message received")
        case Stream.Event.errorOccurred:
            print("error occurred")
            inputStream.close()
            outputStream.close()
            connection = false
            readyWrite = false
            setupNetworkCommunication()
        case Stream.Event.hasSpaceAvailable:
            print("has space available")
            
        case Stream.Event.openCompleted:
            pthread_mutex_lock(&mutex)
            readyWrite = true
            connection = true
            pthread_mutex_unlock(&mutex)
            
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
    
    func restrictAngle(a: Float) -> Float {
        var negative = false
        var angle = a
        if (angle <= 0.05 && angle >= -0.05) { return angle }
        if (angle < -0.05) {
            angle = -angle
            negative = true
        }
        angle = 0.10 * log(angle + 0.05) + 0.2802585
        if (negative) { return -angle }
        return angle
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        
        
        if (!connection)
        {
            setupNetworkCommunication()
        }
        
        if (readyWrite) {
            var vals = Array<NSNumber>()
            vals.append(faceAnchor.blendShapes[.eyeBlinkLeft]!)
            vals.append(faceAnchor.blendShapes[.eyeLookDownLeft]!)
            vals.append(faceAnchor.blendShapes[.eyeLookInLeft]!)
            vals.append(faceAnchor.blendShapes[.eyeLookOutLeft]!)
            vals.append(faceAnchor.blendShapes[.eyeLookUpLeft]!)
            vals.append(faceAnchor.blendShapes[.eyeSquintLeft]!)
            vals.append(faceAnchor.blendShapes[.eyeWideLeft]!)
            vals.append(faceAnchor.blendShapes[.eyeBlinkRight]!)
            vals.append(faceAnchor.blendShapes[.eyeLookDownRight]!)
            vals.append(faceAnchor.blendShapes[.eyeLookInRight]!)
            vals.append(faceAnchor.blendShapes[.eyeLookOutRight]!)
            vals.append(faceAnchor.blendShapes[.eyeLookUpRight]!)
            vals.append(faceAnchor.blendShapes[.eyeSquintRight]!)
            vals.append(faceAnchor.blendShapes[.eyeWideRight]!)
            vals.append(faceAnchor.blendShapes[.jawForward]!)
            vals.append(faceAnchor.blendShapes[.jawLeft]!)
            vals.append(faceAnchor.blendShapes[.jawRight]!)
            vals.append(faceAnchor.blendShapes[.jawOpen]!)
            vals.append(faceAnchor.blendShapes[.mouthClose]!)
            vals.append(faceAnchor.blendShapes[.mouthFunnel]!)
            vals.append(faceAnchor.blendShapes[.mouthPucker]!)
            vals.append(faceAnchor.blendShapes[.mouthLeft]!)
            vals.append(faceAnchor.blendShapes[.mouthRight]!)
            vals.append(faceAnchor.blendShapes[.mouthSmileLeft]!)
            vals.append(faceAnchor.blendShapes[.mouthSmileRight]!)
            vals.append(faceAnchor.blendShapes[.mouthFrownLeft]!)
            vals.append(faceAnchor.blendShapes[.mouthFrownRight]!)
            vals.append(faceAnchor.blendShapes[.mouthDimpleLeft]!)
            vals.append(faceAnchor.blendShapes[.mouthDimpleRight]!)
            vals.append(faceAnchor.blendShapes[.mouthStretchLeft]!)
            vals.append(faceAnchor.blendShapes[.mouthStretchRight]!)
            vals.append(faceAnchor.blendShapes[.mouthRollLower]!)
            vals.append(faceAnchor.blendShapes[.mouthRollUpper]!)
            vals.append(faceAnchor.blendShapes[.mouthShrugLower]!)
            vals.append(faceAnchor.blendShapes[.mouthShrugUpper]!)
            vals.append(faceAnchor.blendShapes[.mouthPressLeft]!)
            vals.append(faceAnchor.blendShapes[.mouthPressRight]!)
            vals.append(faceAnchor.blendShapes[.mouthLowerDownLeft]!)
            vals.append(faceAnchor.blendShapes[.mouthLowerDownRight]!)
            vals.append(faceAnchor.blendShapes[.mouthUpperUpLeft]!)
            vals.append(faceAnchor.blendShapes[.mouthUpperUpRight]!)
            vals.append(faceAnchor.blendShapes[.browDownLeft]!)
            vals.append(faceAnchor.blendShapes[.browDownRight]!)
            vals.append(faceAnchor.blendShapes[.browInnerUp]!)
            vals.append(faceAnchor.blendShapes[.browOuterUpLeft]!)
            vals.append(faceAnchor.blendShapes[.browOuterUpRight]!)
            vals.append(faceAnchor.blendShapes[.cheekPuff]!)
            vals.append(faceAnchor.blendShapes[.cheekSquintLeft]!)
            vals.append(faceAnchor.blendShapes[.cheekSquintRight]!)
            vals.append(faceAnchor.blendShapes[.noseSneerLeft]!)
            vals.append(faceAnchor.blendShapes[.noseSneerRight]!)
            vals.append(faceAnchor.blendShapes[.tongueOut]!)
            valsStr = ""
            for val in vals {
                valsStr += float2data(number: val)
            }
            
            
            //            //UPDATE ROTATION
            let transform = faceAnchor.transform
            let curFrame = sceneView.session.currentFrame
            let proj = curFrame!.camera.projectionMatrix(for: UIInterfaceOrientation.portrait, viewportSize: sceneView.bounds.size, zNear: 0.001, zFar: 1000)
            let view = curFrame!.camera.viewMatrix(for: UIInterfaceOrientation.portrait)
            let proj_view = simd_mul(proj, view)
            let mvp = simd_mul(proj_view, transform)
            let faceMat = SCNMatrix4(mvp)
            let faceNode = SCNNode()
            faceNode.setWorldTransform(faceMat)
            valsStr += float2data(number: NSNumber(value: restrictAngle(faceNode.eulerAngles.x)))
            valsStr += float2data(number: NSNumber(value: restrictAngle(faceNode.eulerAngles.y)))
            var z_angle = faceNode.eulerAngles.z
            if (z_angle > 0) { z_angle -= 3.141592 }
            else { z_angle += 3.141592 }
            z_angle = 0.15 * restrictAngle(a: z_angle)
            valsStr += float2data(number: NSNumber(value: z_angle))
            
//            simd::float4x4 transform = _currentAnchor.transform;
//            __auto_type curFrame = _scnView.session.currentFrame;
//            simd_float4x4 proj = [curFrame.camera projectionMatrixForOrientation:UIInterfaceOrientationPortrait viewportSize:scnViewSize zNear:0.001 zFar:1000];
//            simd_float4x4 view = [curFrame.camera viewMatrixForOrientation:UIInterfaceOrientationPortrait];
//            simd_float4x4 proj_view = simd_mul(proj, view);
//            simd_float4x4 mvp = simd_mul(proj_view, transform);
//            SCNMatrix4 faceMat = SCNMatrix4FromMat4(mvp);
//            SCNNode* faceNode = [[SCNNode alloc] init];
//            [faceNode setTransform:faceMat];
//            angles[0] = restrictAngle(faceNode.eulerAngles.x);
//            angles[1] = restrictAngle(faceNode.eulerAngles.y);
//            float z_angle = faceNode.eulerAngles.z;
//            if (z_angle > 0) z_angle -= 3.14159265359;
//            else z_angle += 3.14159265359;
//            z_angle = 0.15 * restrictAngle(z_angle);
//            angles[2] = z_angle;
//
            
            
            valsStr += "\0\0\0"
            pthread_mutex_lock(&mutex);
            write2Socket(str: valsStr)
            readyWrite = false
            pthread_mutex_unlock(&mutex)
        }
    }

    func float2data(number: NSNumber) -> String {
        return String(format: "%.3f ", number.floatValue)
    }
}


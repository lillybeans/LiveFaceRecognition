//
//  ViewController.swift
//  LiveDetection
//
//  Created by Lilly Tong on 2018-03-17.
//  Copyright © 2018 Lilly Tong. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController {

    @IBOutlet var resultLabel: UILabel!
    var redView: UIView!
    
    @IBOutlet weak var previewView: PreviewView!
    
    private var requests = [VNRequest]()
    
    private var devicePosition: AVCaptureDevice.Position = .back
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: handleFaces) // Default
        requests.append(faceDetectionRequest)
        
        //Start a session to capture input from Camera
        previewView.session = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return } //try? = avoid doCatch
        
        guard let session = previewView.session else { return }
        session.addInput(input)
        session.startRunning()
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(dataOutput)
        

    }
    
    func exifOrientationFromDeviceOrientation() -> UInt32 {
        enum DeviceOrientation: UInt32 {
            case top0ColLeft = 1
            case top0ColRight = 2
            case bottom0ColRight = 3
            case bottom0ColLeft = 4
            case left0ColTop = 5
            case right0ColTop = 6
            case right0ColBottom = 7
            case left0ColBottom = 8
        }
        var exifOrientation: DeviceOrientation
        
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            exifOrientation = .left0ColBottom
        case .landscapeLeft:
            exifOrientation = devicePosition == .front ? .bottom0ColRight : .top0ColLeft
        case .landscapeRight:
            exifOrientation = devicePosition == .front ? .top0ColLeft : .bottom0ColRight
        default:
            exifOrientation = .right0ColTop
        }
        return exifOrientation.rawValue
    }

    func handleFaces(request: VNRequest, error: Error?) {
        
        DispatchQueue.main.async { //UI updates on main queue
            guard let results = request.results as? [VNFaceObservation] else { return }
            self.previewView.removeMask()
            for face in results {
                self.previewView.drawFaceboundingBox(face: face)
            }
        }
        
    }

}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let exifOrientation = CGImagePropertyOrientation(rawValue: exifOrientationFromDeviceOrientation()) else { return }
        var requestOptions: [VNImageOption : Any] = [:]
        
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics : cameraIntrinsicData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(requests)
        }
            
        catch {
            print(error)
        }
        
    }
    
}


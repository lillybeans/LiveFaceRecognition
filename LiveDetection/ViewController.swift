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

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet var resultLabel: UILabel!
    var redView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        
        //Start a session to capture input from Camera
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return } //try? = avoid doCatch
        captureSession.addInput(input)
        captureSession.startRunning()
        
        // Display what phone is seeing full-size
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        
        redView = UIView()
        redView.backgroundColor = .red
        redView.alpha = 0.4
        redView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        view.addSubview(redView)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: SqueezeNet().model) else { return }
        
//        let request = VNCoreMLRequest(model: model) { (finishedReq, Err) in
//
//            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
//
//            guard let firstObservation = results.first else { return }
//
//            DispatchQueue.main.async {
//                self.resultLabel.text = "\(firstObservation.identifier) \(firstObservation.confidence)"
//            }
//        }
        
        let request = VNDetectFaceRectanglesRequest{ (req,err) in
            if let err = err {
                print("failed to detect faces: \(err)")
                return
            }
            
            req.results?.forEach({ (res) in
                print(res)
                
                guard let faceObservation = res as? VNFaceObservation else {
                    return
                }
                
                print(faceObservation.boundingBox)
                
                let width: CGFloat = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
                let height: CGFloat = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
                
                print("width: \(width), height: \(height)")
                print("Face Observation: x - \(faceObservation.boundingBox.origin.x), y - \(faceObservation.boundingBox.origin.y), width - \(faceObservation.boundingBox.width), height - \(faceObservation.boundingBox.height)")
                
                //Starting Coordinates and dimensions of facial detection object
                let x = width * faceObservation.boundingBox.origin.x
                let heightOfBox = height * faceObservation.boundingBox.height
                let y = height * (1 - faceObservation.boundingBox.origin.y) - heightOfBox //since VNFaceObservation returns lower left corner as starting point
                let widthOfBox = width * faceObservation.boundingBox.width //width in the x direction
                
                print("x:\(x), y:\(y), width of box: \(widthOfBox), height of box: \(heightOfBox)")
                
                
            })
        }
        
        //no need to convert pixelBuffer into cgImage, since VNImageRequestHandler can take cvPixelBuffer as input...
        
        //just gotta change request from VNClassificationObservation -> VNDetectFaceRectanglesRequest
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        

    }
    
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }

}


//
//  CardDetectionML.swift
//  CardDetection
//
//  Created by Mahdi Mahjoobi on 6/12/20.
//  Copyright © 2020 Mahdi Mahjoobi. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

class CardDetectionML {
    
    var inputImage: CIImage!
    var didCropRect: ((UIImage) -> Void)?
    
    func cropCardOnImage(uiImage: UIImage) {
        guard let ciImage = CIImage(image: uiImage) else {
            fatalError("can't create CIImage from UIImage")
        }
        
        let orientation = CGImagePropertyOrientation(uiImage.imageOrientation)
        inputImage = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))
        
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: CGImagePropertyOrientation(rawValue: UInt32(Int32(orientation.rawValue)))!)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([self.rectanglesRequest])
            } catch {
                print(error)
            }
        }
    }
    
    private lazy var classificationRequest: VNCoreMLRequest = {
        // Load the ML model through its generated class and create a Vision request for it.
        do {
            let model = try VNCoreMLModel(for: CardDetection().model)
            return VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
        } catch {
            fatalError("can't load Vision ML model: \(error)")
        }
    }()

    private func handleClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNClassificationObservation]
            else { fatalError("unexpected result type from VNCoreMLRequest") }
        guard let best = observations.first
            else { fatalError("can't get best result") }

        DispatchQueue.main.async {
            print("Classification: \"\(best.identifier)\" Confidence: \(best.confidence)")
        }
    }
    
    private lazy var rectanglesRequest: VNDetectRectanglesRequest = {
        return VNDetectRectanglesRequest(completionHandler: self.handleRectangles)
    }()
    
    private func handleRectangles(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRectangleObservation] else {
            print("unexpected result type from VNDetectRectanglesRequest")
            return
        }
        
        guard let detectedRectangle = observations.first else {
            print("No card detected.")
            return
        }
        
        let imageSize = inputImage.extent.size

        // Verify detected rectangle is valid.
        let boundingBox = detectedRectangle.boundingBox.scaled(to: imageSize)
        guard inputImage.extent.contains(boundingBox)
            else { print("invalid card rectangle"); return }

        // Rectify the detected image and reduce it to inverted grayscale for applying model.
        let topLeft = detectedRectangle.topLeft.scaled(to: imageSize)
        let topRight = detectedRectangle.topRight.scaled(to: imageSize)
        let bottomLeft = detectedRectangle.bottomLeft.scaled(to: imageSize)
        let bottomRight = detectedRectangle.bottomRight.scaled(to: imageSize)
        let correctedImage = inputImage
            .cropped(to: boundingBox)
            .applyingFilter("CIPerspectiveCorrection", parameters: [
                "inputTopLeft": CIVector(cgPoint: topLeft),
                "inputTopRight": CIVector(cgPoint: topRight),
                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                "inputBottomRight": CIVector(cgPoint: bottomRight)
            ])
        

        // Show the pre-processed image
        DispatchQueue.main.async {
            self.didCropRect?(UIImage(ciImage: correctedImage))
        }

        // Run the Core ML MNIST classifier -- results in handleClassification method
        let handler = VNImageRequestHandler(ciImage: correctedImage)
        do {
            try handler.perform([classificationRequest])
        } catch {
            print(error)
        }
    }
    
}

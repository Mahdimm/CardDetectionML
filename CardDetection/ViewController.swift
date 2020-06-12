//
//  ViewController.swift
//  CardDetection
//
//  Created by Mahdi Mahjoobi on 6/12/20.
//  Copyright © 2020 Mahdi Mahjoobi. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var correctedImageView: UIImageView!
    @IBOutlet weak var classificationLabel: UILabel!
    
    private let cardDetection = CardDetectionML()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardDetection.didCropRect = { [weak self] image in
            self?.classificationLabel.text = "Card cropped successfuly"
            self?.correctedImageView.image = image
        }
    }

    @IBAction func takePicture(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        present(picker, animated: true)
    }
    
    @IBAction func chooseImage(_ sender: Any) {
        // The photo library is the default source, editing not allowed
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        present(picker, animated: true)
    }
    
    var inputImage: CIImage! // The image to be processed.
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        classificationLabel.text = "Cropping card....."
        correctedImageView.image = nil
        
        guard let uiImage = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.originalImage.rawValue)] as? UIImage
            else { fatalError("no image from image picker") }
        guard let ciImage = CIImage(image: uiImage)
            else { fatalError("can't create CIImage from UIImage") }
        let orientation = CGImagePropertyOrientation(uiImage.imageOrientation)
        inputImage = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))

        imageView.image = uiImage
        cardDetection.cropCardOnImage(uiImage: uiImage)
    }

}


//
//  ViewController.swift
//  WhatFlower?
//
//  Created by Григорий Душин on 01.05.2022.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
    }
    
 

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
        
            guard let convertedCiImage = CIImage(image: userPickedImage) else {
                fatalError("cannot convert ciimage!")
            }
        detect(image: convertedCiImage)
            
        imageView.image = userPickedImage
        }
        
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Cannot import model!")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else{
                fatalError("Could not classify image!")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
let handler = VNImageRequestHandler(ciImage: image)
        do{
       try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts|pageimages",
        "exintro" : "",
        "explaintext" : "",
        "titles" : flowerName,
        "indexpageids" : "" ,
        "redirects" : "1",
        "pithmbsize" : "500"
        ]

        
        AF.request(wikipediaURL, method: .get, parameters: parameters).validate(contentType: ["application/json"]).responseJSON { (response) in
         
        switch response.result {
        case let .success(value):
            print(response)
        let wikipediaJSON = JSON(value)
        if let pageid = wikipediaJSON["query"]["pageids"][0].string {
        if let extract = wikipediaJSON["query"]["pages"][pageid]["extract"].string {
        self.label.numberOfLines = 0
        self.label.text = extract
        self.label.sizeToFit()
            let flowerImageURL = wikipediaJSON["query"]["pages"][pageid]["thumbnail"]["source"].string
            self.imageView.sd_setImage(with: URL(string: flowerImageURL!))
        }
        }
        case let .failure(error):
        fatalError(error.localizedDescription)
        }
        }

    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}


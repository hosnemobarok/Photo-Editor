//
//  ViewController.swift
//  Photo Editor
//
//  Created by Md Hosne Mobarok on 17/3/22.
//

import UIKit

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate{

    @IBOutlet weak var gellaryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButtonUI(button: gellaryButton)
        setupButtonUI(button: cameraButton)
        
    }

    // MARK: PRIVATE METHODS.
    func setupButtonUI(button: UIButton) {
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowColor = UIColor.lightGray.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 5
        button.layer.masksToBounds = false
        
        button.layer.cornerRadius = 8
    }
    
    
    // MARK: - BUTTON ACTION.
    @IBAction func galleryButtonAction(_ sender: UIButton){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    @IBAction func cameraButtonAction(_ sender: UIButton){
        let vc = UIImagePickerController()
        vc.sourceType = .camera //.photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }

        let storyboard = UIStoryboard(name: "Edit", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        vc.originalImage = image
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
        
        // print out the image size as a test
        print(image.size)
    }
    
}

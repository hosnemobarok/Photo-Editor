//
//  EditViewController.swift
//  Photo Editor
//
//  Created by Md Hosne Mobarok on 17/3/22.
//

import UIKit
import AVFoundation
import CoreImage.CIFilterBuiltins
import SwiftUI

enum SelectedButtonTag: Int {
    case rotate
    case crop
    case filter
}

class EditViewController: UIViewController {

    @IBOutlet weak var allEditButtonBackgroundView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var filterButton: UIButton!
    
    var originalImage: UIImage?
    
    /// apply sepia filter
    let context = CIContext()
    
    var outputImage = [UIImage]()
    let filters = [
        "", "CIColorInvert", "CIColorMap","CIColorMonochrome", "CIColorPosterize", "CIFalseColor",
        "CIMinimumComponent", "CIPhotoEffectChrome", "CIPhotoEffectFade", "CIPhotoEffectInstant", "CIPhotoEffectMono","CIColorCrossPolynomial", "CIColorCube",
        "CIPhotoEffectNoir", "CIPhotoEffectProcess", "CIPhotoEffectTonal", "CIPhotoEffectTransfer", "CISepiaTone",
        "CIVignette", "CIVignetteEffect"
    ]
    
    // DeeplabV3 model from https://developer.apple.com/machine-learning/models/
    let model = DeepLabV3()
    let c = CIContext(options: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = originalImage
        setupUI()
        setupCollectionView()
    }
    
    // MARK: - PRIVATE METHODS.
    func setupUI(){
    }
    
    func setupCollectionView(){
        let nib = UINib(nibName: "CollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    // MARK: - BUTTON ACTION
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareImageButton(_ sender: UIButton) {
        imageSaveAndShare()
    }
    
    @objc private func didPinch(_ gesture: UIPinchGestureRecognizer){
        if gesture.state == .changed{
            let scale = gesture.scale
            print(scale)
        }
    }
    
    private func addGesture() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        imageView.addGestureRecognizer(pinchGesture)
    }
    
    ///
    @IBAction func allEditButtonAction(_ sender: UIButton) {
        switch sender.tag {
            
        case SelectedButtonTag.rotate.rawValue:
            print("do something when first button is tapped")
            
        case SelectedButtonTag.crop.rawValue:
            print("do something when second button is tapped")
            
        case SelectedButtonTag.filter.rawValue:
            print("do something when second button is tapped")
            
        default:
            print("remove image background")
            imageView.image = removeBackground(image: imageView.image!)

        }
    }
}

// MARK: - Collectionview Datasorce and Delegate Methods.
extension EditViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        cell.editedImageView.image = setFilter(filterType: filters[indexPath.row])
        
        if indexPath.row == 0 {
            cell.filterName.text = "orginal"
        }else{
            cell.filterName.text = "filter\(indexPath.row)"
        }
        
        outputImage.append(cell.editedImageView.image!)
        return cell
    }
    
    private func setFilter(filterType: String) -> UIImage {
        let filter = CIFilter(name: filterType)
        if filterType == "CISepiaTone" {
            filter?.setValue(2.0, forKey: kCIInputIntensityKey)
        }
        
        filter?.setValue(CIImage(image: originalImage!), forKey: kCIInputImageKey)
        let output = filter?.outputImage

        if output == nil {
            return originalImage!
        }
        return UIImage(cgImage: self.context.createCGImage(output!, from: output!.extent)!)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        imageView.image = outputImage[indexPath.row]
    }

}


// MARK: - Share image extension
extension EditViewController {
    
    func imageSaveAndShare() {
        /// Save PDF file
        guard let outputURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(UUID())").appendingPathExtension("jpg")
        else { fatalError("Destination URL not created") }
        
        if let data = imageView.image?.jpegData(compressionQuality:  1.0) {
            do {
                // writes the image data to disk
                try data.write(to: outputURL)
                print("file saved")
            } catch {
                print("error saving file:", error)
            }
        }
                    
        if FileManager.default.fileExists(atPath: outputURL.path){
            let url = URL(fileURLWithPath: outputURL.path)
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            
            //If user on iPad
            if UIDevice.current.userInterfaceIdiom == .pad {
                if activityViewController.responds(to: #selector(getter: UIViewController.popoverPresentationController)) {
                    activityViewController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                }
            }
            //present(activityViewController, animated: true, completion: nil)
            present(activityViewController, animated: true)
            
            activityViewController.completionWithItemsHandler = { activity, success, items, error in
                //print("activity: \(String(describing: activity)), success: \(success), items: \(String(describing: items)), error: \(error)")
                if activity == nil {
                    guard ((try? FileManager.default.removeItem(at: url)) != nil) else { return }
                }
            }
        } else {
            print("document was not found")
        }
    }
}


// MARK: - Image Background remove
extension EditViewController {
    private func removeBackground(image:UIImage) -> UIImage?{
        let resizedImage = image.resized(to: CGSize(width: 513, height: 513))
        if let pixelBuffer = resizedImage.pixelBuffer(width: Int(resizedImage.size.width), height: Int(resizedImage.size.height)){
            if let outputImage = (try? model.prediction(image: pixelBuffer))?.semanticPredictions.image(min: 0, max: 1, axes: (0,0,1)), let outputCIImage = CIImage(image:outputImage){
                if let maskImage = removeWhitePixels(image:outputCIImage), let resizedCIImage = CIImage(image: resizedImage), let compositedImage = composite(image: resizedCIImage, mask: maskImage){
                    return UIImage(ciImage: compositedImage).resized(to: CGSize(width: image.size.width, height: image.size.height))
                }
            }
        }
        return nil
    }
    
    private func removeWhitePixels(image:CIImage) -> CIImage?{
        let chromaCIFilter = chromaKeyFilter()
        chromaCIFilter?.setValue(image, forKey: kCIInputImageKey)
        return chromaCIFilter?.outputImage
    }
    
    private func composite(image:CIImage,mask:CIImage) -> CIImage?{
        return CIFilter(name:"CISourceOutCompositing",parameters:
                            [kCIInputImageKey: image,kCIInputBackgroundImageKey: mask])?.outputImage
    }
    
    // modified from https://developer.apple.com/documentation/coreimage/applying_a_chroma_key_effect
    private func chromaKeyFilter() -> CIFilter? {
        let size = 64
        var cubeRGB = [Float]()
        
        for z in 0 ..< size {
            let blue = CGFloat(z) / CGFloat(size-1)
            for y in 0 ..< size {
                let green = CGFloat(y) / CGFloat(size-1)
                for x in 0 ..< size {
                    let red = CGFloat(x) / CGFloat(size-1)
                    let brightness = getBrightness(red: red, green: green, blue: blue)
                    let alpha: CGFloat = brightness == 1 ? 0 : 1
                    cubeRGB.append(Float(red * alpha))
                    cubeRGB.append(Float(green * alpha))
                    cubeRGB.append(Float(blue * alpha))
                    cubeRGB.append(Float(alpha))
                }
            }
        }
        
        let data = Data(buffer: UnsafeBufferPointer(start: &cubeRGB, count: cubeRGB.count))

        let colorCubeFilter = CIFilter(name: "CIColorCube", parameters: ["inputCubeDimension": size, "inputCubeData": data])
        return colorCubeFilter
    }
    
    // modified from https://developer.apple.com/documentation/coreimage/applying_a_chroma_key_effect
    private func getBrightness(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
        let color = UIColor(red: red, green: green, blue: blue, alpha: 1)
        var brightness: CGFloat = 0
        color.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        return brightness
    }
}

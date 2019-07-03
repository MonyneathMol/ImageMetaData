//
//  ViewController.swift
//  ImagePicker
//
//  Created by MonyneathMOL on 7/3/19.
//  Copyright © 2019 Monyneath. All rights reserved.
//

import UIKit
import AssetsLibrary
import PhotosUI

typealias TypeAliaseTEst = (Any?)->()
var onTypeAliaseCalled  : TypeAliaseTEst?

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var btn: UIButton!
    
    @IBOutlet weak var taMetaResponse: UITextView!

    var imagePicker: ImagePicker!
    var text : String = ""
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
       
        onTypeAliaseCalled = { datas in
            //Do sth
    
//           print("data Res \(datas)")
            self.taMetaResponse.text = "\(String(describing: datas))"
             
        }
    }

    @IBAction func btnSelected(_ sender: UIButton) {
        
        
           self.imagePicker.present(from: sender)
    }

    
}

extension ViewController: ImagePickerDelegate {
    
    func didSelect(image: UIImage?) {
        self.imageView.image = image
        print("Response \(self.imagePicker.dataString)")
        taMetaResponse.text = self.imagePicker.dataString
        
        
    }
    
    
}





public protocol ImagePickerDelegate: class {
    func didSelect(image: UIImage?)
}

open class ImagePicker: NSObject {
    
    var dataString : String?
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?
    
   
    
    public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()
        
        super.init()
        
        self.presentationController = presentationController
        self.delegate = delegate
        
        self.pickerController.delegate = self
        self.pickerController.allowsEditing = true
        self.pickerController.mediaTypes = ["public.image"]
    }
    
    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }
        
        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }
    
    public func present(from sourceView: UIView) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let action = self.action(for: .camera, title: "Take photo") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .savedPhotosAlbum, title: "Camera roll") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .photoLibrary, title: "Photo library") {
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }
        
        self.presentationController?.present(alertController, animated: true)
    }
    
    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)
        
        self.delegate?.didSelect(image: image)
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {
    
   
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            return self.pickerController(picker, didSelect: nil)
        }
        //------Solution 1. [WORK]-----------
      /*
        let library = ALAssetsLibrary()
        let url: NSURL = info[UIImagePickerController.InfoKey.referenceURL] as! NSURL
        library.asset(for: url as URL, resultBlock: { (asset: ALAsset?) in
            if asset != nil {
                //print the creation date
                print(asset!.value(forProperty: ALAssetPropertyLocation))
            }
        }, failureBlock: { (error: Error?) in
            NSLog("Error \(error)")
        })
 
 */
        //----------
        
        
        //-------SOlutution 2 -------
        if let assetURL = info[UIImagePickerController.InfoKey.referenceURL] as? NSURL{
            let asset = PHAsset.fetchAssets(withALAssetURLs: [assetURL as URL], options: nil)
            guard let result = asset.firstObject else {
                return
            }
            
            let imageManager = PHImageManager.default()
            imageManager.requestImageData(for: result , options: nil, resultHandler:{
                (data, responseString, imageOriet, info) -> Void in
                let imageData: NSData = data! as NSData
                if let imageSource = CGImageSourceCreateWithData(imageData, nil) {
                    let imageProperties2 = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)! as NSDictionary
                    print("imageProperties2: ", imageProperties2)
                    print("\n\n\n gps:\n\(imageProperties2["{GPS}"])\n\n")
                    let gps = imageProperties2["{GPS}"] as? NSDictionary
                    
                    
                    self.dataString = "\(imageProperties2)"
                    print("\n\n\n lat = \(self.dataString)")
                    
                    onTypeAliaseCalled?(imageProperties2)
                }
                
            })
        }
        
        //--------------------------
        
        self.pickerController(picker, didSelect: image)
    }
}

extension ImagePicker: UINavigationControllerDelegate {
    
}

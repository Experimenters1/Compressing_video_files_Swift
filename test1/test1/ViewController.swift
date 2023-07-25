//
//  ViewController.swift
//  test1
//
//  Created by huy on 7/24/23.
//

import UIKit
import AVFoundation
import MobileCoreServices
import CoreMedia
import AssetsLibrary
import Photos

class ViewController: UIViewController {
    
    var isPlaying = true
    var isSliderEnd = true
    var playbackTimeCheckerTimer: Timer! = nil
    let playerObserver: Any? = nil
    
    let exportSession: AVAssetExportSession! = nil
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playerLayer: AVPlayerLayer!
    var asset: AVAsset!
    
    var url:NSURL! = nil
    var startTime: CGFloat = 0.0
    var stopTime: CGFloat  = 0.0
    var thumbTime: CMTime!
    var thumbtimeSeconds: Int!
    
    var videoPlaybackPosition: CGFloat = 0.0
    var cache:NSCache<AnyObject, AnyObject>!

    
 
    @IBOutlet weak var layoutContainer: UIView!
    
    @IBOutlet weak var selectButton: UIButton!
    
    
    @IBOutlet weak var Img_Layer: UIImageView!
    
    
    @IBOutlet weak var Compress_Videos: UIButton!
    
    
    
    @IBOutlet weak var Videos_Size_test: UIView!
    @IBOutlet weak var Original_Size: UILabel!
    
    
    
    @IBOutlet weak var Compressed_Size_test: UIView!
    @IBOutlet weak var Target_Size: UILabel!
    
    
    @IBOutlet weak var Compression_Rate: UISlider!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let fileManager = FileManager.default
        guard let documentsFolderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        print(documentsFolderURL)
        loadViews()
    }
    
    func loadViews()
    {
      //Whole layout view
        layoutContainer.layer.borderWidth = 1.0
        layoutContainer.layer.borderColor = UIColor.white.cgColor
      
        selectButton.layer.cornerRadius = 5.0
        Compress_Videos.layer.cornerRadius   = 5.0
      
      //Hiding buttons and view on load
        Compress_Videos.isHidden         = true
        Videos_Size_test.isHidden          = true
        Compressed_Size_test.isHidden            = true
        Compression_Rate.isHidden = true
      
      //Style for startTime
        Original_Size.layer.cornerRadius = 5.0
        Original_Size.layer.borderWidth  = 1.0
        Original_Size.layer.borderColor  = UIColor.white.cgColor
      
      //Style for endTime
        Target_Size.layer.cornerRadius = 5.0
        Target_Size.layer.borderWidth  = 1.0
        Target_Size.layer.borderColor  = UIColor.white.cgColor
      

      
      player = AVPlayer()

      
      //Allocating NsCahe for temp storage
      cache = NSCache()
    }
    
    
    //Action for select Video
    @IBAction func selectVideoUrl(_ sender: Any) {
        //Selecting Video type
        let myImagePickerController        = UIImagePickerController()
        myImagePickerController.sourceType = .photoLibrary
        myImagePickerController.mediaTypes = [(kUTTypeMovie) as String]
        myImagePickerController.delegate   = self
        myImagePickerController.isEditing  = false
        present(myImagePickerController, animated: true, completion: {  })
    }
    
    //Action for Compress Videos
    
    @IBAction func Compress_Videos(_ sender: Any) {
        let start = Float(Original_Size.text!)
        let end   = Float(Target_Size.text!)
        

        
    }
    
}


import AVFoundation
import UIKit

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    // Delegate method of image picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)

        if let mediaURL = info[.mediaURL] as? URL {
            let asset = AVURLAsset(url: mediaURL)

            // Perform any operations with the asset, e.g., displaying the video, getting video duration, etc.

            // Example: Display video thumbnail in Img_Layer
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 600)
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                Img_Layer.image = thumbnail
            } catch {
                print("Error generating thumbnail: \(error)")
            }

            // Example: Get video duration in seconds
            let duration = CMTimeGetSeconds(asset.duration)

            // Call the viewAfterVideoIsPicked function and pass the info dictionary
            viewAfterVideoIsPicked(info: info)
        }
    }

    func viewAfterVideoIsPicked(info: [UIImagePickerController.InfoKey: Any]) {
        //Rmoving player if already exists
        if playerLayer != nil {
            playerLayer.removeFromSuperlayer()
        }

        //unhide buttons and view after video selection
        Compress_Videos.isHidden = false
        Videos_Size_test.isHidden = false
        Compressed_Size_test.isHidden = false
        Compression_Rate.isHidden = false

        // Set isSliderEnd to true (assuming this variable is declared somewhere in your code)
        isSliderEnd = true

        // Reset the Original_Size label to show the file size of the selected video
        if let mediaURL = info[.mediaURL] as? URL {
            let asset = AVURLAsset(url: mediaURL)

            // Get the file size in bytes
            let fileSize = getFileSize(for: mediaURL)

            // Convert the file size to a human-readable string
            let formattedSize = stringFromByteCount(fileSize)

            // Display the file size in the Original_Size label
            Original_Size.text = formattedSize
        }

        // Set the Target_Size label to show the thumbtimeSeconds value (assuming this variable is declared somewhere in your code)
//        Target_Size.text = "\(thumbtimeSeconds!)"
    }

    //Tap action on video player
    @objc func tapOnVideoLayer(tap: UITapGestureRecognizer) {
        if isPlaying {
            player.play()
        } else {
            player.pause()
        }
        isPlaying = !isPlaying
    }

    // Function to get the file size of a given URL
    func getFileSize(for url: URL) -> Int64 {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = fileAttributes[.size] as? Int64 {
                return fileSize
            } else {
                return 0
            }
        } catch {
            print("Error getting file size: \(error)")
            return 0
        }
    }

    // Function to convert bytes to a human-readable string
    func stringFromByteCount(_ byteCount: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: byteCount)
    }
}

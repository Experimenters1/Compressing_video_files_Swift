//
//  ViewController.swift
//  test4
//
//  Created by Huy Vu on 8/7/23.
//

import UIKit
import AVFoundation
import MobileCoreServices
import CoreMedia
import AssetsLibrary
import Photos

class ViewController: UIViewController {

    @IBOutlet weak var layoutContainer: UIView!
    
    @IBOutlet weak var Img_Layer: UIImageView!
    
    @IBOutlet weak var selectButton: UIButton!
    
    @IBOutlet weak var Compress_Videos: UIButton!
    
    
    var player: AVPlayer!
    var cache:NSCache<AnyObject, AnyObject>!
    var selectedMediaURL: URL? // Property to store the selected mediaURL
    
    var playerLayer: AVPlayerLayer!
    
    // Khai báo biến videoURL1 dưới kiểu dữ liệu URL
     var videoURL1: URL?
        
    
    
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
    
    //Action for crop video
    @IBAction func Compress_Videos(_ sender: Any) {
        let fileManager = FileManager.default
        
        guard let documentsFolderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        // Đường dẫn của thư mục "Compress_video" trong Documents
        let compressVideoFolderURL = documentsFolderURL.appendingPathComponent("Compress_video")
        
        do {
            // Kiểm tra xem thư mục có tồn tại không
            if !fileManager.fileExists(atPath: compressVideoFolderURL.path) {
                // Nếu thư mục không tồn tại, tạo mới
                try fileManager.createDirectory(at: compressVideoFolderURL, withIntermediateDirectories: true, attributes: nil)
                print("Đã tạo thư mục Compress_video thành công!")
            } else {
                print("Thư mục Compress_video đã tồn tại!")
            }
        } catch {
            print("Lỗi khi tạo thư mục Compress_video: \(error)")
        }
        
        // Sử dụng biến exportPath để truyền đường dẫn của thư mục Compress_video vào các bước xử lý tiếp theo.
        let exportPath = compressVideoFolderURL.path // ... Đặt đường dẫn cho video sau khi nén ...
        
        // Check if videoURL1 is nil before using it
               guard let videoURL = videoURL1 else {
                   print("No video selected.")
                   return
               }
        
        // Call compressVideoAndExport function to compress and export the video
        let renderSize = CGSize(width: 640, height: 480)
        
        let compressedURL = documentsFolderURL.appendingPathComponent("compressedVideo.mp4")
        
        // Call the compress function with the selected video URL
        compress(videoPath: videoURL, exportVideoPath: compressedURL, renderSize: CGSize(width: 640, height: 480)) { success in
            if success {
                print("Video compression successful.")
            } else {
                print("Video compression failed.")
            }
        }
    }
    

}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // Delegate method for image picker
           func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
               if let videoURL = info[.mediaURL] as? URL {
           
                   
                   print("huy 466r63637 \(videoURL)")
                   
                   self.videoURL1 = videoURL
                  
                   
                   // Call the viewAfterVideoIsPicked function and pass the info dictionary
                   viewAfterVideoIsPicked(info: info)
                   
                   let asset = AVURLAsset(url: videoURL)
                   
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

                   picker.dismiss(animated: true, completion: nil)
               }
           }
    
    func viewAfterVideoIsPicked(info: [UIImagePickerController.InfoKey: Any]) {
        //Rmoving player if already exists
        if playerLayer != nil {
            playerLayer.removeFromSuperlayer()
        }

        //unhide buttons and view after video selection
        Compress_Videos.isHidden = false
       
    }
        
        func compress(videoPath: URL, exportVideoPath: URL, renderSize: CGSize, completion: @escaping (Bool) -> ()) {
            // Kiểm tra giá trị của videoPath và exportVideoPath trước khi sử dụng
            guard videoPath != nil, exportVideoPath != nil else {
                print("Invalid video paths.")
                completion(false)
                return
            }
            
            let asset = AVURLAsset(url: videoPath)
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
                completion(false)
                return
            }

            exportSession.outputURL = exportVideoPath
            exportSession.outputFileType = AVFileType.mp4
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.videoComposition = createVideoComposition(for: asset, renderSize: renderSize)

            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    completion(true)
                case .failed, .cancelled, .unknown:
                    completion(false)
                default:
                    break
                }
            }
        }

        func createVideoComposition(for asset: AVAsset, renderSize: CGSize) -> AVMutableVideoComposition? {
            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize = renderSize
            videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: CMTime.zero, duration: asset.duration)

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: asset.tracks(withMediaType: .video)[0])
            let transform = CGAffineTransform(scaleX: renderSize.width / asset.tracks(withMediaType: .video)[0].naturalSize.width,
                                              y: renderSize.height / asset.tracks(withMediaType: .video)[0].naturalSize.height)
            layerInstruction.setTransform(transform, at: CMTime.zero)

            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]

            return videoComposition
        }
        

    
}

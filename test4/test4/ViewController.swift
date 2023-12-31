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
    
    @IBOutlet weak var Compressing_75: UIButton!
    
    @IBOutlet weak var Compressing_25: UIButton!
    
    
    var player: AVPlayer!
    var cache:NSCache<AnyObject, AnyObject>!
    var selectedMediaURL: URL? // Property to store the selected mediaURL
    
    var playerLayer: AVPlayerLayer!
    
    // Khai báo biến videoURL1 dưới kiểu dữ liệu URL
     var videoURL1: URL?
    
    var compressedURL: URL?
    
    var mySize: CGSize = CGSize(width: 0, height: 0) // Khởi tạo mySize với giá trị mặc định
    
    var isPercent_70 = false
    
    var isPercent_25 = false
        
    
    
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
        
        Compressing_75.isHidden = true
        Compressing_25.isHidden = true
        
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
        
        // Gọi hàm showFileNameInputDialog
            showFileNameInputDialog { [weak self] compressedURL in
                guard let self = self else { return }

                // Tiến hành nén video và truyền compressedURL vào hàm compress
                if let videoURL = self.videoURL1 {
//                    let renderSize = CGSize(width: 640, height: 480)
                    
//                    let renderSize = CGSize(width: 320, height: 240)
                    
//                    let renderSize = CGSize(width: 960, height: 540)
                    
                    
                    let renderSize = self.mySize // Sử dụng giá trị của mySize
                    
                    self.compress(videoPath: videoURL, exportVideoPath: compressedURL, renderSize: renderSize) { success in
                        if success {
                            print("Video compression successful.")
                        } else {
                            print("Video compression failed.")
                        }
                    }
                }
            }
    }
    
    
    func showFileNameInputDialog(completion: @escaping (URL) -> Void) {
        let alertController = UIAlertController(title: "Nhập tên và định dạng", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Tên tập tin"
        }
        alertController.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: nil))

        let saveAction = UIAlertAction(title: "Lưu", style: .default) { [weak self] _ in
            guard let textField = alertController.textFields?.first, var fileName = textField.text else {
                return
            }

            var fileCount = 0
            let fileManager = FileManager.default
            let documentsFolderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let compressVideoFolderURL = documentsFolderURL.appendingPathComponent("Compress_video")

            do {
                if !fileManager.fileExists(atPath: compressVideoFolderURL.path) {
                    try fileManager.createDirectory(at: compressVideoFolderURL, withIntermediateDirectories: true, attributes: nil)
                    print("Đã tạo thư mục Compress_video thành công!")
                } else {
                    print("Thư mục Compress_video đã tồn tại!")
                }
            } catch {
                print("Lỗi khi tạo thư mục Compress_video: \(error)")
            }

            var compressedURL: URL

            repeat {
                let formattedFileName = fileCount == 0 ? fileName : "\(fileName)_\(fileCount)"
                let formattedFileNameWithExtension = formattedFileName + ".mp4"
                compressedURL = compressVideoFolderURL.appendingPathComponent(formattedFileNameWithExtension)

                if !fileManager.fileExists(atPath: compressedURL.path) {
                    break
                }

                fileCount += 1
            } while true

            self?.compressedURL = compressedURL
            completion(compressedURL)
        }

        alertController.addAction(saveAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func Compressing_75(_ sender: Any) {
        Compressing_25.setImage(UIImage(named: "work-in-progress"), for: .normal)
        toggleOrientation_75()
        Data_transmission_75()

    }
    
    // Hàm để thay đổi giá trị của isLandscape
    func toggleOrientation_75() {
        isPercent_70 = !isPercent_70
    }
    
    func Data_transmission_75() {
        if isPercent_70 {
            Compressing_75.setImage(UIImage(named: "img1"), for: .normal)
            
                    mySize.width = 320
                    mySize.height = 240
            
            
            
            Compress_Videos.isHidden = false
            
           
        } else {
            Compressing_75.setImage(UIImage(named: "work-in-progress 1"), for: .normal)
            Compress_Videos.isHidden = true
            
        }
    }
    
    // Hàm để thay đổi giá trị của isLandscape
    func toggleOrientation_25() {
        isPercent_25 = !isPercent_25
     
    }
    
    func Data_transmission_25() {
        if isPercent_25 {
            Compressing_25.setImage(UIImage(named: "img2"), for: .normal)
      
            
                    mySize.width = 960
                    mySize.height = 540
            
           
            Compress_Videos.isHidden = false
            

        } else {
            Compressing_25.setImage(UIImage(named: "work-in-progress"), for: .normal)
            Compress_Videos.isHidden = true
            
        }
    }
    
    @IBAction func Compressing_25(_ sender: Any) {
        Compressing_75.setImage(UIImage(named: "work-in-progress 1"), for: .normal)
        toggleOrientation_25()
        Data_transmission_25()
    }
    
}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // Delegate method for image picker
           func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
               if let videoURL = info[.mediaURL] as? URL {
           
                   
       
                   
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

//        //unhide buttons and view after video selection
        Compressing_75.isHidden = false
        Compressing_25.isHidden = false
       
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

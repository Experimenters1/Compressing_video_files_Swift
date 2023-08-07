//
//  ViewController.swift
//  test3
//
//  Created by Huy Vu on 8/4/23.
//

import UIKit
import MobileCoreServices
import AVFoundation
import VideoToolbox

class ViewController: UIViewController , UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        
        let fileManager = FileManager.default
        guard let documentsFolderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        print(documentsFolderURL)
    }

    @IBAction func selectVideoUrl(_ sender: Any) {
        //Selecting Video type
                let myImagePickerController        = UIImagePickerController()
                myImagePickerController.sourceType = .photoLibrary
                myImagePickerController.mediaTypes = [(kUTTypeMovie) as String]
                myImagePickerController.delegate   = self
                myImagePickerController.isEditing  = false
                present(myImagePickerController, animated: true, completion: {  })
    }
    
    
    // Delegate method for image picker
       func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
           if let videoURL = info[.mediaURL] as? URL {
               let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
               let compressedURL = documentsURL.appendingPathComponent("compressedVideo.mp4")
               
               print("huy 466r63637 \(videoURL)")
               
               // Call the compress function with the selected video URL
               compress(videoPath: videoURL, exportVideoPath: compressedURL, renderSize: CGSize(width: 640, height: 480)) { success in
                   if success {
                       print("Video compression successful.")
                   } else {
                       print("Video compression failed.")
                   }
               }

               picker.dismiss(animated: true, completion: nil)
           }
       }
    
    func compress(videoPath: URL, exportVideoPath: URL, renderSize: CGSize, completion: @escaping (Bool) -> ()) {
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


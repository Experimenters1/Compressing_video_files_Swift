//
//  ViewController.swift
//  test2
//
//  Created by Huy Vu on 8/2/23.
//

import UIKit
import AVFoundation
import MobileCoreServices
import CoreMedia
import AssetsLibrary
import Photos
 
class ViewController: UIViewController {

    @IBOutlet weak var layoutContainer_test: UIView!
    
    @IBOutlet weak var selectButton_test: UIButton!
    
    
    @IBOutlet weak var Img_Layer_test: UIImageView!
    
    @IBOutlet weak var Compress_Videos_test: UIButton!
    
    var player: AVPlayer!
    var cache:NSCache<AnyObject, AnyObject>!
    var selectedMediaURL: URL? // Property to store the selected mediaURL
    
    var playerLayer: AVPlayerLayer!
    
    
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
          layoutContainer_test.layer.borderWidth = 1.0
          layoutContainer_test.layer.borderColor = UIColor.white.cgColor
        
        selectButton_test.layer.cornerRadius = 5.0
        Compress_Videos_test.layer.cornerRadius   = 5.0
        
        //Hiding buttons and view on load
          Compress_Videos_test.isHidden         = true
        
        
        player = AVPlayer()

        
        //Allocating NsCahe for temp storage
        cache = NSCache()
        
    }
    
    
    //Action for select Video
    @IBAction func selectVideoUrl_test(_ sender: Any) {
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
                
                // Check if a video is selected
                guard let mediaURL = self.selectedMediaURL else {
                    print("No video selected.")
                    return
                }
                
                // Call compressVideoAndExport function to compress and export the video
               let renderSize = CGSize(width: 640, height: 480)
        
        compress(videoPath: mediaURL.path, exportVideoPath: exportPath, renderSize: renderSize) { success in
            if success {
                print("Nén video thành công!")
            } else {
                print("Nén video thất bại.")
            }
        }
    }
    

}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // Delegate method of image picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
           picker.dismiss(animated: true, completion: nil)
           
           if let mediaURL = info[.mediaURL] as? URL {
               
               // Save the selected mediaURL to the selectedMediaURL property
               self.selectedMediaURL = mediaURL

               let asset = AVURLAsset(url: mediaURL)
               
               // Perform any operations with the asset, e.g., displaying the video, getting video duration, etc.
               
               // Example: Display video thumbnail in Img_Layer
               let imageGenerator = AVAssetImageGenerator(asset: asset)
               imageGenerator.appliesPreferredTrackTransform = true
               let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 600)
               do {
                   let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                   let thumbnail = UIImage(cgImage: cgImage)
                   Img_Layer_test.image = thumbnail
               } catch {
                   print("Error generating thumbnail: \(error)")
               }
               
               // Example: Get video duration in seconds
               let duration = CMTimeGetSeconds(asset.duration)
               
               // Call the viewAfterVideoIsPicked function and pass the info dictionary
               viewAfterVideoIsPicked(info: info)
               
              
               
               print("huy 12333333333333 : \(mediaURL)")

           }
       }
    
    
    func viewAfterVideoIsPicked(info: [UIImagePickerController.InfoKey: Any]) {
        //Rmoving player if already exists
        if playerLayer != nil {
            playerLayer.removeFromSuperlayer()
        }

        //unhide buttons and view after video selection
        Compress_Videos_test.isHidden = false
       
    }
    
    
    func existsFileAtUrl(_ url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }

    
    
    func compress(videoPath: String, exportVideoPath: String, renderSize: CGSize, completion: @escaping (Bool) -> ()) {
        let videoUrl = URL(fileURLWithPath: videoPath)

        if (!existsFileAtUrl(videoUrl)) {
            completion(false)
            return
        }

        let videoAssetUrl = AVURLAsset(url: videoUrl)

        let videoTrackArray = videoAssetUrl.tracks(withMediaType: .video)

        if videoTrackArray.count < 1 {
            completion(false)
            return
        }

        let videoAssetTrack = videoTrackArray[0]

        let audioTrackArray = videoAssetUrl.tracks(withMediaType: .audio)

        if audioTrackArray.count < 1 {
            completion(false)
            return
        }

        let audioAssetTrack = audioTrackArray[0]

        // input readers
        let outputUrl = URL(fileURLWithPath: exportVideoPath)
        let videoWriter = try! AVAssetWriter(url: outputUrl, fileType: .mov)
        videoWriter.shouldOptimizeForNetworkUse = true

        let vSettings = videoSettings(renderSize)
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: vSettings)
        videoWriterInput.expectsMediaDataInRealTime = false
        videoWriterInput.transform = videoAssetTrack.preferredTransform
        videoWriter.add(videoWriterInput)

        let aSettings = audioSettings()
        let audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: aSettings)
        audioWriterInput.expectsMediaDataInRealTime = false
        audioWriterInput.transform = audioAssetTrack.preferredTransform
        videoWriter.add(audioWriterInput)

        // output readers
            let videoReaderSettings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            ]
            let videoReaderOutput = AVAssetReaderTrackOutput(track: videoAssetTrack, outputSettings: videoReaderSettings)
            let videoReader = try! AVAssetReader(asset: videoAssetUrl)
            videoReader.add(videoReaderOutput)

        var settings = [String: Any]()
        settings[AVFormatIDKey] = kAudioFormatLinearPCM as NSNumber
        let audioReaderOutput = AVAssetReaderTrackOutput(track: audioAssetTrack, outputSettings: settings)
        let audioReader = try! AVAssetReader(asset: videoAssetUrl)
        audioReader.add(audioReaderOutput)

        videoWriter.startWriting()

        videoReader.startReading()
        videoWriter.startSession(atSourceTime: CMTime.zero)

        let processingVideoQueue = DispatchQueue(label: "processingVideoCompressionQueue")

        videoWriterInput.requestMediaDataWhenReady(on: processingVideoQueue) {
            while (videoWriterInput.isReadyForMoreMediaData) {

                let sampleVideoBuffer = videoReaderOutput.copyNextSampleBuffer()
                if (videoReader.status == .reading && sampleVideoBuffer != nil) {
                    videoWriterInput.append(sampleVideoBuffer!)
                } else {
                    videoWriterInput.markAsFinished()

                    if (videoReader.status == .completed) {

                        audioReader.startReading()
                        videoWriter.startSession(atSourceTime: CMTime.zero)

                        let processingAudioQueue = DispatchQueue(label: "processingAudioCompressionQueue")

                        audioWriterInput.requestMediaDataWhenReady(on: processingAudioQueue) {
                            while (audioWriterInput.isReadyForMoreMediaData) {
                                let sampleAudioBuffer = audioReaderOutput.copyNextSampleBuffer()
                                if (audioReader.status == .reading && sampleAudioBuffer != nil) {
                                    audioWriterInput.append(sampleAudioBuffer!)
                                } else {
                                    audioWriterInput.markAsFinished()

                                    if (audioReader.status == .completed) {
                                        videoWriter.finishWriting {
                                            completion(true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    func videoSettings(_ size: CGSize) -> [String: Any] {
        let compressionSettings: [String: Any] = [
            AVVideoAverageBitRateKey: 425000
        ]
        
        let settings: [String: Any] = [
            AVVideoCompressionPropertiesKey: compressionSettings,
            AVVideoCodecKey: AVVideoCodecType.h264.rawValue,
            AVVideoHeightKey: size.height,
            AVVideoWidthKey: size.width
        ]
        
        return settings
    }

    func audioSettings() -> [String: Any] {
        // Set up the channel layout
        var channelLayout = AudioChannelLayout()
        memset(&channelLayout, 0, MemoryLayout<AudioChannelLayout>.size)
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        let channelLayoutData = Data(bytes: &channelLayout, count: MemoryLayout<AudioChannelLayout>.size)
        
        // Set up a dictionary with our output settings
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 96000,
            AVChannelLayoutKey: channelLayoutData
        ]
        
        return settings
    }

}


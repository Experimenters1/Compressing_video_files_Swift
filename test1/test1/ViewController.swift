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
    
    var selectedMediaURL: URL? // Property to store the selected mediaURL
    
    
    // Original size of the selected video
        var originalVideoSize: Int64 = 0


    
 
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
        let renderSize = CGSize(width: 1280, height: 720)
        compressVideoAndExport(at: mediaURL, exportPath: exportPath, renderSize: renderSize) { success in
            if success {
                // Ghi log hoặc xử lý sau khi hoàn thành nén
                print("Compression and export completed successfully.")
            } else {
                // Xử lý khi không thể nén và xuất video
                print("Compression and export failed.")
            }
        }
    }
    
    
    @IBAction func sliderValueChange(_ sender: UISlider) {
        // Calculate compressed video size based on the slider value
                let compressionRate = Double(Compression_Rate.value)
                let compressedVideoSize = calculateCompressedVideoSize(compressionRate: compressionRate)

                // Update Target_Size UILabel with compressed video size
                Target_Size.text = stringFromByteCount(compressedVideoSize)
    }
    
    // Function to calculate compressed video size based on compression rate
        func calculateCompressedVideoSize(compressionRate: Double) -> Int64 {
            let compressedSize = Double(originalVideoSize) * (1.0 - compressionRate)
            return Int64(compressedSize)
        }

        // Function to set up the maximum value for the Compression_Rate UISlider
        func setSliderMaximumValue() {
            Compression_Rate.maximumValue = Float(originalVideoSize)
        }

        // Function to get the original video size and set up the UISlider
        func prepareVideoForCompression() {
            guard let mediaURL = self.selectedMediaURL else {
                return
            }

            // Get the original video size
            originalVideoSize = getFileSize(for: mediaURL)

            // Update Original_Size UILabel with the original video size
            Original_Size.text = stringFromByteCount(originalVideoSize)

            // Set up the maximum value for the slider based on the original video size
            setSliderMaximumValue()
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
                   Img_Layer.image = thumbnail
               } catch {
                   print("Error generating thumbnail: \(error)")
               }
               
               // Example: Get video duration in seconds
               let duration = CMTimeGetSeconds(asset.duration)
               
               // Call the viewAfterVideoIsPicked function and pass the info dictionary
               viewAfterVideoIsPicked(info: info)
               
               // Call the function to prepare video for compression
                prepareVideoForCompression()
               
               print("huy 12333333333333 : \(mediaURL)")

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
    
    
    // Hàm gộp video và nén video
    func compressVideoAndExport(at mediaURL: URL, exportPath: String, renderSize: CGSize, completion: @escaping (Bool) -> Void) {
        compress(videoURL: mediaURL, exportVideoPath: exportPath, renderSize: renderSize) { success in
            if success {
                // Ghi log hoặc xử lý sau khi hoàn thành nén
                print("Compression completed successfully.")
            } else {
                // Xử lý khi không thể nén
                print("Compression failed.")
            }
            completion(success)
        }
    }




    func compress(videoURL: URL, exportVideoPath: String, renderSize: CGSize, completion: @escaping (Bool) -> Void) {
        let videoAsset = AVURLAsset(url: videoURL)
        let videoTrackArray = videoAsset.tracks(withMediaType: .video)
        let audioTrackArray = videoAsset.tracks(withMediaType: .audio)

        guard videoTrackArray.count > 0, audioTrackArray.count > 0 else {
            completion(false)
            return
        }

        let videoAssetTrack = videoTrackArray[0]
        let audioAssetTrack = audioTrackArray[0]

        let outputURL = URL(fileURLWithPath: exportVideoPath)
        let videoWriter: AVAssetWriter
        do {
            videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        } catch {
            print("Error creating AVAssetWriter: \(error)")
            completion(false)
            return
        }

        let videoSettings = videoSettings(renderSize: renderSize)
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoWriterInput.expectsMediaDataInRealTime = false
        videoWriterInput.transform = videoAssetTrack.preferredTransform
        videoWriter.add(videoWriterInput)

        let audioSettings = audioSettings()
        let audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioWriterInput.expectsMediaDataInRealTime = false
        videoWriter.add(audioWriterInput)

        let videoReaderOutput = AVAssetReaderTrackOutput(track: videoAssetTrack, outputSettings: nil)
        let videoReader: AVAssetReader
        do {
            videoReader = try AVAssetReader(asset: videoAsset)
        } catch {
            print("Error creating AVAssetReader: \(error)")
            completion(false)
            return
        }

        videoReader.add(videoReaderOutput)

        let audioReaderOutput = AVAssetReaderTrackOutput(track: audioAssetTrack, outputSettings: nil)
        let audioReader: AVAssetReader
        do {
            audioReader = try AVAssetReader(asset: videoAsset)
        } catch {
            print("Error creating AVAssetReader: \(error)")
            completion(false)
            return
        }

        audioReader.add(audioReaderOutput)

        videoWriter.startWriting()
        videoReader.startReading()
        videoWriter.startSession(atSourceTime: .zero)

        let processingVideoQueue = DispatchQueue(label: "processingVideoCompressionQueue")

        videoWriterInput.requestMediaDataWhenReady(on: processingVideoQueue) {
            while videoWriterInput.isReadyForMoreMediaData {
                guard let sampleBuffer = videoReaderOutput.copyNextSampleBuffer() else {
                    videoWriterInput.markAsFinished()

                    if videoReader.status == .completed {
                        audioReader.startReading()
                        videoWriter.startSession(atSourceTime: .zero)

                        let processingAudioQueue = DispatchQueue(label: "processingAudioCompressionQueue")

                        audioWriterInput.requestMediaDataWhenReady(on: processingAudioQueue) {
                            while audioWriterInput.isReadyForMoreMediaData {
                                guard let sampleBuffer = audioReaderOutput.copyNextSampleBuffer() else {
                                    audioWriterInput.markAsFinished()

                                    if audioReader.status == .completed {
                                        videoWriter.finishWriting {
                                            completion(true)
                                        }
                                    }
                                    return
                                }
                                audioWriterInput.append(sampleBuffer)
                            }
                        }
                    }
                    return
                }
                videoWriterInput.append(sampleBuffer)
            }
        }
    }

    func videoSettings(renderSize: CGSize) -> [String: Any] {
        var compressionSettings: [String: Any] = [:]
        compressionSettings[AVVideoAverageBitRateKey] = 425000

        var settings: [String: Any] = [:]
        settings[AVVideoCompressionPropertiesKey] = compressionSettings
        settings[AVVideoCodecKey] = AVVideoCodecType.h264
        settings[AVVideoHeightKey] = renderSize.height
        settings[AVVideoWidthKey] = renderSize.width

        return settings
    }

    func audioSettings() -> [String: Any] {
        // Set up the channel layout
        var channelLayout = AudioChannelLayout()
        memset(&channelLayout, 0, MemoryLayout<AudioChannelLayout>.size)
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono

        // Set up a dictionary with our output settings
        var settings: [String: Any] = [:]
        settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
        settings[AVSampleRateKey] = 44100
        settings[AVNumberOfChannelsKey] = 1
        settings[AVEncoderBitRateKey] = 96000
        settings[AVChannelLayoutKey] = NSData(bytes: &channelLayout, length: MemoryLayout<AudioChannelLayout>.size)

        return settings
    }
    
    
    
}

//
//  ViewController.swift
//  test3
//
//  Created by Huy Vu on 8/4/23.
//

import UIKit
import MobileCoreServices
import AVFoundation

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

               // Call the compress function with the selected video URL
               compress(videoPath: videoURL.path, exportVideoPath: compressedURL.path, renderSize: CGSize(width: 640, height: 480)) { success in
                   if success {
                       print("Video compression successful.")
                   } else {
                       print("Video compression failed.")
                   }
               }

               picker.dismiss(animated: true, completion: nil)
           }
       }
    
    func fileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }

    
    func compress(videoPath: String, exportVideoPath: String, renderSize: CGSize, completion: @escaping (Bool) -> ()) {
        let videoUrl = URL(fileURLWithPath: videoPath)

        if !fileExists(at: videoUrl) {
            completion(false)
            return
        }

        let videoAssetUrl = AVURLAsset(url: videoUrl, options: nil)

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
        guard let videoWriter = try? AVAssetWriter(url: outputUrl, fileType: .mp4) else {
            completion(false)
            return
        }

        videoWriter.shouldOptimizeForNetworkUse = true

        let vSettings = videoSettings(size: renderSize)
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
        let videoReaderSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
        let videoReaderOutput = AVAssetReaderTrackOutput(track: videoAssetTrack, outputSettings: videoReaderSettings)
        guard let videoReader = try? AVAssetReader(asset: videoAssetUrl) else {
            completion(false)
            return
        }
        videoReader.add(videoReaderOutput)

        var settings = [String: Any]()
        settings[AVFormatIDKey] = kAudioFormatLinearPCM
        let audioReaderOutput = AVAssetReaderTrackOutput(track: audioAssetTrack, outputSettings: settings)
        guard let audioReader = try? AVAssetReader(asset: videoAssetUrl) else {
            completion(false)
            return
        }
        audioReader.add(audioReaderOutput)

        videoWriter.startWriting()
        videoReader.startReading()
        videoWriter.startSession(atSourceTime: CMTime.zero)

        let processingVideoQueue = DispatchQueue(label: "processingVideoCompressionQueue")
        videoWriterInput.requestMediaDataWhenReady(on: processingVideoQueue) {
            while videoWriterInput.isReadyForMoreMediaData {
                guard let sampleVideoBuffer = videoReaderOutput.copyNextSampleBuffer() else {
                    videoWriterInput.markAsFinished()

                    if videoReader.status == .completed {
                        audioReader.startReading()
                        videoWriter.startSession(atSourceTime: CMTime.zero)

                        let processingAudioQueue = DispatchQueue(label: "processingAudioCompressionQueue")
                        audioWriterInput.requestMediaDataWhenReady(on: processingAudioQueue) {
                            while audioWriterInput.isReadyForMoreMediaData {
                                guard let sampleAudioBuffer = audioReaderOutput.copyNextSampleBuffer() else {
                                    audioWriterInput.markAsFinished()

                                    if audioReader.status == .completed {
                                        videoWriter.finishWriting {
                                            completion(true)
                                        }
                                    }
                                    return
                                }
                                audioWriterInput.append(sampleAudioBuffer)
                            }
                        }
                    }
                    return
                }
                videoWriterInput.append(sampleVideoBuffer)
            }
        }
    }

           
    func videoSettings(size: CGSize) -> [String : Any] {
        let compressionSettings: [String : Any] = [
            AVVideoAverageBitRateKey : 425000,
        ]

        let settings: [String : Any] = [
            AVVideoCompressionPropertiesKey : compressionSettings,
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoHeightKey : size.height,
            AVVideoWidthKey : size.width,
        ]

        return settings
    }

    func audioSettings() -> [String : Any] {
        var channelLayout = AudioChannelLayout()
        memset(&channelLayout, 0, MemoryLayout<AudioChannelLayout>.size)
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono

        let settings: [String : Any] = [
            AVFormatIDKey : kAudioFormatMPEG4AAC,
            AVSampleRateKey : 44100,
            AVNumberOfChannelsKey : 1,
            AVEncoderBitRateKey : 96000,
            AVChannelLayoutKey : NSData(bytes: &channelLayout, length: MemoryLayout<AudioChannelLayout>.size)
        ]

        return settings
    }


    
}


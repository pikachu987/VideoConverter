//MIT License
//
//Copyright (c) 2020 pikachu987 <pikachu77769@gmail.com>
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.

import UIKit
import AVKit

open class VideoConverter {
    public let asset: AVAsset
    public let presets: [String]

    public var option: ConverterOption?

    private var assetExportsSession: AVAssetExportSession?
    private var timer: Timer?

    private var progressCallback: ((Double?) -> Void)?

    private var videoTrack: AVAssetTrack? {
        return self.asset.tracks(withMediaType: .video).first
    }

    private var radian: CGFloat? {
        guard let videoTrank = self.videoTrack else { return nil }
        return atan2(videoTrank.preferredTransform.b, videoTrank.preferredTransform.a) + (self.option?.rotate ?? 0)
    }

    private var converterDegree: ConverterDegree? {
        guard let radian = self.radian else { return nil }
        let degree = radian * 180 / .pi
        return ConverterDegree.convert(degree: degree)
    }

    private var naturalSize: CGSize? {
        guard let videoTrack = self.videoTrack,
            let converterDegree = self.converterDegree else { return nil }
        if converterDegree == .degree90 || converterDegree == .degree270 {
            return CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
        } else {
            return CGSize(width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
        }
    }

    private var cropFrame: CGRect? {
        guard let crop = self.option?.convertCrop else { return nil }
        guard let naturalSize = self.naturalSize else { return nil }
        let contrastSize = crop.contrastSize
        let frame = crop.frame
        let cropX = frame.origin.x * naturalSize.width / contrastSize.width
        let cropY = frame.origin.y * naturalSize.height / contrastSize.height
        let cropWidth = frame.size.width * naturalSize.width / contrastSize.width
        let cropHeight = frame.size.height * naturalSize.height / contrastSize.height
        let cropFrame = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        return cropFrame
    }

    public init(asset: AVAsset) {
        self.asset = asset
        self.presets = AVAssetExportSession.exportPresets(compatibleWith: asset)
    }

    // Restore
    open func restore() {
        self.option = nil
        self.assetExportsSession?.cancelExport()
        self.assetExportsSession = nil
        self.timer?.invalidate()
        self.timer = nil
        self.progressCallback = nil
    }

    // Convert
    open func convert(_ option: ConverterOption? = nil, temporaryFileName: String? = nil, progress: ((Double?) -> Void)? = nil, completion: @escaping ((URL?, Error?) -> Void)) {
        self.restore()
        guard let videoTrack = self.videoTrack else {
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "Can't find video", code: 404, userInfo: nil))
            }
            return
        }
        self.option = option
        if self.renderSize?.width == 0 || self.renderSize?.height == 0 {
            self.restore()
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "The crop size is too small", code: 503, userInfo: nil))
            }
            return
        }

        let composition = AVMutableComposition()

        var trackTimeRange: CMTimeRange
        if let trimRange = option?.trimRange {
            trackTimeRange = trimRange
        } else {
            trackTimeRange = CMTimeRange(start: .zero, duration: self.asset.duration)
        }

        guard let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            self.restore()
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "Can't find video", code: 404, userInfo: nil))
            }
            return
        }

        // trim
        try? videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: .zero)

        // mute
        if !(option?.isMute ?? false) {
            if let audioTrack = self.asset.tracks(withMediaType: AVMediaType.audio).first {
                let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                // mute trim
                try? audioCompositionTrack?.insertTimeRange(trackTimeRange, of: audioTrack, at: .zero)
            }
        }

        let compositionInstructions = AVMutableVideoCompositionInstruction()
        compositionInstructions.timeRange = CMTimeRange(start: .zero, duration: self.asset.duration)
        compositionInstructions.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1).cgColor

        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
        // opacity
        layerInstructions.setOpacity(1.0, at: .zero)
        // transform
        if let transform = self.transform {
            layerInstructions.setTransform(transform, at: .zero)
        }
        compositionInstructions.layerInstructions = [layerInstructions]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [compositionInstructions]
        // size
        if let renderSize = self.renderSize {
            videoComposition.renderSize = renderSize
        }
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        // saveFile
        let temporaryFileName = temporaryFileName ?? "TrimmedMovie.mp4"
        let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())\(temporaryFileName)")
        try? FileManager.default.removeItem(at: url)

        self.progressCallback = progress
        // progress timer
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (time) in
                    if let progress = self?.assetExportsSession?.progress {
                        self?.progressCallback?(Double(progress))
                        if progress >= 1 {
                            self?.timer?.invalidate()
                            self?.timer = nil
                        }
                    } else if self?.assetExportsSession == nil {
                        self?.timer?.invalidate()
                        self?.timer = nil
                    }
                }
            } else {
                self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: true)
            }
        }

        // quality
        let presetName = option?.quality ?? AVAssetExportPresetHighestQuality
        self.assetExportsSession = AVAssetExportSession(asset: composition, presetName: presetName)
        self.assetExportsSession?.outputFileType = AVFileType.mp4
        self.assetExportsSession?.shouldOptimizeForNetworkUse = true
        self.assetExportsSession?.videoComposition = videoComposition
        self.assetExportsSession?.outputURL = url

        self.assetExportsSession?.exportAsynchronously(completionHandler: {
            self.timer?.invalidate()
            self.timer = nil
            DispatchQueue.main.async {
                self.progressCallback?(1)
                self.progressCallback = nil
                if let url = self.assetExportsSession?.outputURL, self.assetExportsSession?.status == .completed {
                    completion(url, nil)
                } else {
                    completion(nil, self.assetExportsSession?.error)
                }
                self.restore()
            }
        })
    }

    // Video Size
    private var renderSize: CGSize? {
        guard let naturalSize = self.naturalSize else { return nil }
        var renderSize = naturalSize
        if let cropFrame = self.cropFrame {
            let width = floor(cropFrame.size.width / 16) * 16
            let height = floor(cropFrame.size.height / 16) * 16
            renderSize = CGSize(width: width, height: height)
        }
        return renderSize
    }

    // Video Rotate & Rrigin
    private var transform: CGAffineTransform? {
        guard let naturalSize = self.naturalSize,
            let radian = self.radian,
            let converterDegree = self.converterDegree else { return nil }

        var transform = CGAffineTransform.identity
            transform = transform.rotated(by: radian)
        if converterDegree == .degree90 {
            transform = transform.translatedBy(x: 0, y: -naturalSize.width)
        } else if converterDegree == .degree180 {
            transform = transform.translatedBy(x: -naturalSize.width, y: -naturalSize.height)
        } else if converterDegree == .degree270 {
            transform = transform.translatedBy(x: -naturalSize.height, y: 0)
        }

        if let cropFrame = self.cropFrame {
            if converterDegree == .degree0 {
                transform = transform.translatedBy(x: -cropFrame.origin.x, y: -cropFrame.origin.y)
            } else if converterDegree == .degree90 {
                transform = transform.translatedBy(x: -cropFrame.origin.y, y: cropFrame.origin.x)
            } else if converterDegree == .degree180 {
                transform = transform.translatedBy(x: cropFrame.origin.x, y: cropFrame.origin.y)
            } else if converterDegree == .degree270 {
                transform = transform.translatedBy(x: cropFrame.origin.y, y: -cropFrame.origin.x)
            }
        }
        return transform
    }

    // Progress Time Timer
    @objc private func timerAction(_ sender: Timer) {
        if let progress = self.assetExportsSession?.progress {
            self.progressCallback?(Double(progress))
            if progress >= 1 {
                self.timer?.invalidate()
                self.timer = nil
            }
        } else if self.assetExportsSession == nil {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}

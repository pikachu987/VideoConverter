//
//  ViewController.swift
//  VideoConverter
//
//  Created by pikachu987 on 09/13/2020.
//  Copyright (c) 2020 pikachu987. All rights reserved.
//

import UIKit
import VideoConverter
import VideoTrim
import AVKit
import AVFoundation
import Photos

class ViewController: UIViewController {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()

    private let videoView: VideoView = {
        let videoView = VideoView(viewType: .default)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        return videoView
    }()

    private let videoTrim: VideoTrim = {
        let videoTrim = VideoTrim()
        videoTrim.translatesAutoresizingMaskIntoConstraints = false
        videoTrim.topMargin = 4
        videoTrim.bottomMargin = 8
        return videoTrim
    }()

    private let convertVideoView: VideoView = {
        let videoView = VideoView(viewType: .convert)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        return videoView
    }()

    private let toolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 35))
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()

    private let progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = 0
        return progressView
    }()

    private let fileDownloadProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = 0
        progressView.isHidden = true
        return progressView
    }()

    private var cropBarButtonItem: UIBarButtonItem?
    private var rotateBarButtonItem: UIBarButtonItem?
    private var qualityBarButtonItem: UIBarButtonItem?
    private var muteBarButtonItem: UIBarButtonItem?

    private var videoConverter: VideoConverter?

    private var isPlaying = false

    private var rotate: Double = 0

    private var isMute: Bool {
        return self.muteBarButtonItem?.title?.lowercased() == "Mute On".lowercased()
    }

    private var preset: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .black

        self.view.addSubview(self.scrollView)
        self.view.addSubview(self.fileDownloadProgressView)
        self.scrollView.addSubview(self.containerView)

        self.containerView.addSubview(self.videoView)
        self.containerView.addSubview(self.videoTrim)
        self.containerView.addSubview(self.toolbar)
        self.containerView.addSubview(self.progressView)
        self.containerView.addSubview(self.convertVideoView)

        self.view.addConstraints([
            NSLayoutConstraint(item: self.scrollView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.scrollView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.scrollView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.scrollView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        let containerViewHeightConstraint = NSLayoutConstraint(item: self.containerView, attribute: .height, relatedBy: .equal, toItem: self.scrollView, attribute: .height, multiplier: 1, constant: 0)
        containerViewHeightConstraint.priority = UILayoutPriority(rawValue: 1)
        self.scrollView.addConstraints([
            NSLayoutConstraint(item: self.containerView, attribute: .leading, relatedBy: .equal, toItem: self.scrollView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.containerView, attribute: .trailing, relatedBy: .equal, toItem: self.scrollView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.containerView, attribute: .top, relatedBy: .equal, toItem: self.scrollView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.containerView, attribute: .bottom, relatedBy: .equal, toItem: self.scrollView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.containerView, attribute: .width, relatedBy: .equal, toItem: self.scrollView, attribute: .width, multiplier: 1, constant: 0),
            containerViewHeightConstraint
        ])

        self.containerView.addConstraints([
            NSLayoutConstraint(item: self.videoView, attribute: .top, relatedBy: .equal, toItem: self.containerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.videoView, attribute: .leading, relatedBy: .equal, toItem: self.containerView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.videoView, attribute: .trailing, relatedBy: .equal, toItem: self.containerView, attribute: .trailing, multiplier: 1, constant: 0)
        ])

        self.containerView.addConstraints([
            NSLayoutConstraint(item: self.videoTrim, attribute: .top, relatedBy: .equal, toItem: self.videoView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.videoTrim, attribute: .leading, relatedBy: .equal, toItem: self.containerView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.videoTrim, attribute: .trailing, relatedBy: .equal, toItem: self.containerView, attribute: .trailing, multiplier: 1, constant: 0)
        ])

        self.containerView.addConstraints([
            NSLayoutConstraint(item: self.toolbar, attribute: .top, relatedBy: .equal, toItem: self.videoTrim, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.toolbar, attribute: .leading, relatedBy: .equal, toItem: self.containerView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.toolbar, attribute: .trailing, relatedBy: .equal, toItem: self.containerView, attribute: .trailing, multiplier: 1, constant: 0)
        ])

        self.containerView.addConstraints([
            NSLayoutConstraint(item: self.progressView, attribute: .top, relatedBy: .equal, toItem: self.toolbar, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.progressView, attribute: .leading, relatedBy: .equal, toItem: self.containerView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.progressView, attribute: .trailing, relatedBy: .equal, toItem: self.containerView, attribute: .trailing, multiplier: 1, constant: 0)
        ])

        self.progressView.addConstraints([
            NSLayoutConstraint(item: self.progressView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 2)
        ])

        self.containerView.addConstraints([
            NSLayoutConstraint(item: self.convertVideoView, attribute: .top, relatedBy: .equal, toItem: self.progressView, attribute: .bottom, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: self.convertVideoView, attribute: .leading, relatedBy: .equal, toItem: self.containerView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.convertVideoView, attribute: .trailing, relatedBy: .equal, toItem: self.containerView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.convertVideoView, attribute: .bottom, relatedBy: .equal, toItem: self.containerView, attribute: .bottom, multiplier: 1, constant: 0)
        ])
        
        let topConstant = self.navigationController?.navigationBar.frame.height ?? 0
        self.view.addConstraints([
            NSLayoutConstraint(item: self.fileDownloadProgressView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: UIApplication.shared.statusBarFrame.height + topConstant),
            NSLayoutConstraint(item: self.fileDownloadProgressView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.fileDownloadProgressView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
        ])

        self.fileDownloadProgressView.addConstraints([
            NSLayoutConstraint(item: self.fileDownloadProgressView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 2)
        ])

        let button = UIButton(type: .system)
        button.setTitle("Videos", for: .normal)
        button.addTarget(self, action: #selector(self.videoTap(_:)), for: .touchUpInside)
        self.navigationItem.titleView = button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.convertTap(_:)))

        self.cropBarButtonItem = UIBarButtonItem(title: "Crop", style: .plain, target: self, action: #selector(self.cropTap(_:)))
        self.rotateBarButtonItem = UIBarButtonItem(title: "Rotate", style: .plain, target: self, action: #selector(self.rotateTap(_:)))
        self.qualityBarButtonItem = UIBarButtonItem(title: "Quality", style: .plain, target: self, action: #selector(self.qualityTap(_:)))
        self.muteBarButtonItem = UIBarButtonItem(title: "Mute Off", style: .plain, target: self, action: #selector(self.muteTap(_:)))

        var toolbarItems = [UIBarButtonItem]()
        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        if let barButtonItem = self.cropBarButtonItem {
            toolbarItems.append(barButtonItem)
        }
        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        if let barButtonItem = self.rotateBarButtonItem {
            toolbarItems.append(barButtonItem)
        }
        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        if let barButtonItem = self.qualityBarButtonItem {
            toolbarItems.append(barButtonItem)
        }
        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        if let barButtonItem = self.muteBarButtonItem {
            toolbarItems.append(barButtonItem)
        }
        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))

        self.toolbar.setItems(toolbarItems, animated: false)

        self.videoView.delegate = self
        self.videoTrim.delegate = self

        self.permission { (alertController) in
            if alertController != nil {
                self.showPublicVideo()
                return
            }
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            let assets = PHAsset.fetchAssets(with: fetchOptions)
            if let asset = assets.lastObject {
                let videoRequestOptions = PHVideoRequestOptions()
                videoRequestOptions.isNetworkAccessAllowed = true
                PHCachingImageManager.default().requestAVAsset(forVideo: asset, options: videoRequestOptions) { (asset, _, _) in
                    DispatchQueue.main.async {
                        if let urlAsset = asset as? AVURLAsset {
                            self.videoView.url = urlAsset.url
                            let asset = AVAsset(url: urlAsset.url)
                            self.videoTrim.asset = asset
                            self.videoConverter = VideoConverter(asset: asset)
                            self.updateTrimTime()
                        } else if let asset = asset {
                            self.videoView.asset = asset
                            self.videoTrim.asset = asset
                            self.videoConverter = VideoConverter(asset: asset)
                            self.updateTrimTime()
                        }
                    }
                }
            } else {
                self.showPublicVideo()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.videoView.invalidate()
        self.convertVideoView.invalidate()
    }

    // MARK: Convert
    @objc private func convertTap(_ sender: UIBarButtonItem) {
        guard let videoConverter = self.videoConverter else { return }

        var videoConverterCrop: ConverterCrop?
        if let dimFrame = self.videoView.dimFrame {
            videoConverterCrop = ConverterCrop(frame: dimFrame, contrastSize: self.videoView.videoRect.size)
        }
        videoConverter.convert(ConverterOption(
            trimRange: CMTimeRange(start: self.videoTrim.startTime, duration: self.videoTrim.durationTime),
            convertCrop: videoConverterCrop,
            rotate: CGFloat(.pi/2 * self.rotate),
            quality: self.preset,
            isMute: self.isMute), progress: { [weak self] (progress) in
                self?.progressView.setProgress(Float(progress ?? 0), animated: false)
        }, completion: { [weak self] (url, error) in
            if let error = error {
                let alertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: nil))
                self?.present(alertController, animated: true)
            } else {
                self?.convertVideoView.url = url
                self?.progressView.setProgress(0, animated: false)
            }
        })
    }
}

// MARK: ViewController + Update Trim
extension ViewController {
    private func updateTrimTime() {
        self.videoView.startTime = self.videoTrim.startTime
        self.videoView.endTime = self.videoTrim.endTime
        self.videoView.durationTime = self.videoTrim.durationTime
    }
}

// MARK: ViewController + Crop & Rotate & Qulity & Mute
extension ViewController {
    @objc private func cropTap(_ sender: UIBarButtonItem) {
        guard let asset = self.videoView.player?.currentItem?.asset,
            let currentTime = self.videoView.player?.currentTime() else { return }
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        guard let imageRef = try? imageGenerator.copyCGImage(at: currentTime, actualTime: nil) else { return }
        guard let image = UIImage(cgImage: imageRef).rotate(radians: Float(CGFloat(.pi/2 * self.rotate))) else { return }
        let viewController = CropViewController(image: image)
        viewController.delegate = self
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .fullScreen
        self.present(navigationController, animated: true, completion: nil)
    }

    @objc private func rotateTap(_ sender: UIBarButtonItem) {
        var transform = CGAffineTransform.identity
        self.rotate += 1
        if self.rotate == 4 {
            self.rotate = 0
            self.videoView.degree = 0
        } else {
            let rotate = CGFloat(.pi/2 * self.rotate)
            transform = transform.rotated(by: rotate)
            self.videoView.degree = rotate * 180 / CGFloat.pi
        }
        self.videoView.dimFrame = nil
        self.videoView.containerView.transform = transform
    }

    @objc private func qualityTap(_ sender: UIBarButtonItem) {
        guard let asset = self.videoView.player?.currentItem?.asset else { return }
        let presets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        presets.forEach { (preset) in
            alertController.addAction(UIAlertAction(title: preset, style: .default, handler: { (_) in
                self.preset = preset
            }))
        }
        self.present(alertController, animated: true)
    }

    @objc private func muteTap(_ sender: UIBarButtonItem) {
        self.muteBarButtonItem?.title = self.isMute ? "Mute Off" : "Mute On"
        self.videoView.isMute = self.isMute
    }
}

// MARK: ViewController + Video Albums & Camera
extension ViewController {
    @objc private func videoTap(_ sender: UIButton) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Albums", style: .default, handler: { (_) in
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.mediaTypes = ["public.movie"]
            pickerController.sourceType = .photoLibrary
            self.present(pickerController, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (_) in
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.mediaTypes = ["public.movie"]
            pickerController.sourceType = .camera
            self.present(pickerController, animated: true, completion: nil)
        }))
        self.present(alertController, animated: true)
    }
}

// MARK: ViewController + showPublicVideo
extension ViewController {
    private func showPublicVideo() {
        guard let url = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4") else { return }
        self.fileDownloadProgressView.isHidden = false
        self.fileDownloadProgressView.progress = 0
        DispatchQueue.global().async {
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
            let downloadTask = session.downloadTask(with: url)
            downloadTask.resume()
        }
    }
}

// MARK: ViewController + URLSessionDownloadDelegate
extension ViewController: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let targetURL = tempDirectoryURL.appendingPathComponent("ForBiggerBlazes.mp4")
        try? FileManager.default.moveItem(at: location, to: targetURL)
        DispatchQueue.main.async {
            self.fileDownloadProgressView.isHidden = true
            self.fileDownloadProgressView.progress = 1

            self.videoView.url = targetURL
            let asset = AVAsset(url: targetURL)
            self.videoTrim.asset = asset
            self.videoConverter = VideoConverter(asset: asset)
            self.updateTrimTime()
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.fileDownloadProgressView.progress = Float(progress)
        }
    }
}

// MARK: ViewController + Permission
extension ViewController {
    private func permission(_ handler: @escaping ((UIAlertController?) -> Void)) {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            DispatchQueue.main.async { handler(nil) }
        } else if PHPhotoLibrary.authorizationStatus() == .denied {
            let alertController = UIAlertController(title: "Permission", message: "Permission", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: nil))
            handler(alertController)
        } else {
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    DispatchQueue.main.async { handler(nil) }
                default:
                    let alertController = UIAlertController(title: "Permission", message: "Permission", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: nil))
                    handler(alertController)
                }
            }
        }
    }
}

// MARK: ViewController + UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let url = info[.mediaURL] as? URL else { return }
        self.preset = nil
        self.rotate = 0
        self.videoView.containerView.transform = CGAffineTransform.identity
        self.videoView.degree = 0
        self.videoView.url = url
        let asset = AVAsset(url: url)
        self.videoTrim.asset = asset
        self.videoView.restoreCrop()
        self.videoConverter = VideoConverter(asset: asset)
        self.updateTrimTime()
    }
}

// MARK: ViewController + VideoDelegate
extension ViewController: VideoDelegate {
    func videoPlaying() {
        self.videoTrim.currentTime = self.videoView.player?.currentTime()
    }
}

// MARK: ViewController + VideoTrimDelegate
extension ViewController: VideoTrimDelegate {
    func videoTrimStartTrimChange(_ view: VideoTrim) {
        self.isPlaying = self.videoView.isPlaying
        self.videoView.pause()
    }

    func videoTrimEndTrimChange(_ view: VideoTrim) {
        self.updateTrimTime()
        if self.isPlaying {
            self.videoView.play()
        }
    }

    func videoTrimPlayTimeChange(_ view: VideoTrim) {
        self.videoView.player?.seek(to: CMTime(value: CMTimeValue(view.playTime.value + view.startTime.value), timescale: view.playTime.timescale))
        self.updateTrimTime()
    }
}

// MARK: ViewController + CropDelegate
extension ViewController: CropDelegate {
    func cropImage(_ imageSize: CGSize, cropFrame: CGRect) {
        let videoRect = self.videoView.videoRect
        let frameX = cropFrame.origin.x * videoRect.size.width / imageSize.width
        let frameY = cropFrame.origin.y * videoRect.size.height / imageSize.height
        let frameWidth = cropFrame.size.width * videoRect.size.width / imageSize.width
        let frameHeight = cropFrame.size.height * videoRect.size.height / imageSize.height
        let dimFrame = CGRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight)
        self.videoView.dimFrame = dimFrame
    }
}

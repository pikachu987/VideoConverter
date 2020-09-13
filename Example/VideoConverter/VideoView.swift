//
//  VideoView.swift
//  VideoConverter_Example
//
//  Created by Apple on 2020/09/13.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AVKit

protocol VideoDelegate: class {
    func videoPlaying()
}

class VideoView: UIView {
    private let viewType: VideoViewType

    weak var delegate: VideoDelegate?

    let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let playerContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let dimView: DimView = {
        let dimView = DimView()
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.backgroundColor = UIColor(white: 0/255, alpha: 0.8)
        return dimView
    }()

    private let playerLayer: AVPlayerLayer = {
        return AVPlayerLayer()
    }()

    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var videoRect: CGRect {
        if self.degree == 0 || self.degree == 180 {
            return self.playerLayer.videoRect
        } else if self.degree == 90 || self.degree == 270 {
            return CGRect(x: self.playerLayer.videoRect.origin.y, y: self.playerLayer.videoRect.origin.x, width: self.playerLayer.videoRect.size.height, height: self.playerLayer.videoRect.size.width)
        } else {
            return .zero
        }
    }

    var player: AVPlayer? {
        return self.playerLayer.player
    }

    private var timer: Timer?

    var asset: AVAsset? {
        didSet {
            if let asset = self.asset {
                self.playerLayer.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                self.playerLayer.frame = self.playerContainerView.bounds

                if self.viewType == .convert {
                    self.startTime = .zero
                    self.endTime = self.player?.currentItem?.asset.duration ?? .zero
                }
            }
        }
    }

    var url: URL? {
        didSet {
            if let url = self.url {
                self.playerLayer.player = AVPlayer(url: url)
                self.playerLayer.frame = self.playerContainerView.bounds

                if self.viewType == .convert {
                    self.startTime = .zero
                    self.endTime = self.player?.currentItem?.asset.duration ?? .zero
                }
            }
        }
    }

    var isMute: Bool = false {
        didSet {
            self.player?.isMuted = self.isMute
        }
    }

    var isPlaying: Bool {
        guard let player = self.player else { return false }
        return player.rate != 0 && player.error == nil
    }

    var degree: CGFloat = 0 {
        didSet {
            let dimFrame = self.dimFrame
            self.dimFrame = dimFrame
        }
    }

    var dimFrame: CGRect? = nil {
        didSet {
            if let dimFrame = self.dimFrame {
                var maskX: CGFloat = 0
                var maskY: CGFloat = 0
                var maskWidth: CGFloat = 0
                var maskHeight: CGFloat = 0
                if self.degree == 0 || self.degree == 180 {
                    maskX = ((self.dimView.frame.width - self.playerLayer.videoRect.width) / 2) + dimFrame.origin.x
                    maskY = ((self.dimView.frame.height - self.playerLayer.videoRect.height) / 2) + dimFrame.origin.y
                    maskWidth = dimFrame.width
                    maskHeight = dimFrame.height
                } else if self.degree == 90 || self.degree == 270 {
                    maskX = ((self.dimView.frame.width - self.playerLayer.videoRect.height) / 2) + dimFrame.origin.x
                    maskY = ((self.dimView.frame.height - self.playerLayer.videoRect.width) / 2) + dimFrame.origin.y
                    maskWidth = dimFrame.width
                    maskHeight = dimFrame.height
                }
                let rect = CGRect(x: maskX, y: maskY, width: maskWidth, height: maskHeight)
                let path = UIBezierPath(rect: rect)
                path.append(UIBezierPath(rect: self.dimView.bounds))
                self.dimView.mask(path.cgPath, duration: 0, animated: false)
                self.dimView.isHidden = false
            } else {
                self.dimView.isHidden = true
            }
        }
    }

    var startTime: CMTime = .zero
    var endTime: CMTime = .zero
    var durationTime: CMTime = .zero

    init(viewType: VideoViewType) {
        self.viewType = viewType
        super.init(frame: .zero)

        self.backgroundColor = .black

        self.addSubview(self.containerView)
        self.addSubview(self.dimView)
        self.addSubview(self.playButton)
        self.containerView.addSubview(self.playerContainerView)

        let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 240)
        heightConstraint.priority = UILayoutPriority(rawValue: 950)
        self.addConstraints([
            heightConstraint
        ])

        self.addConstraints([
            NSLayoutConstraint(item: self.containerView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.containerView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.containerView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.containerView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        self.addConstraints([
            NSLayoutConstraint(item: self.dimView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.dimView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.dimView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.dimView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        self.addConstraints([
            NSLayoutConstraint(item: self.playButton, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playButton, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        self.containerView.addConstraints([
            NSLayoutConstraint(item: self.playerContainerView, attribute: .leading, relatedBy: .equal, toItem: self.containerView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playerContainerView, attribute: .trailing, relatedBy: .equal, toItem: self.containerView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playerContainerView, attribute: .top, relatedBy: .equal, toItem: self.containerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playerContainerView, attribute: .bottom, relatedBy: .equal, toItem: self.containerView, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        self.playerContainerView.layoutIfNeeded()
        self.playerContainerView.layer.addSublayer(self.playerLayer)
        self.playerLayer.frame = self.playerContainerView.bounds

        self.playButton.addTarget(self, action: #selector(self.togglePlay(_:)), for: .touchUpInside)
        DispatchQueue.main.async {
            self.restoreCrop()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func togglePlay(_ sender: UIButton) {
        if self.isPlaying {
            self.pause()
        } else {
            self.play()
        }
    }

    @objc private func timerAction(_ sender: Timer) {
        self.delegate?.videoPlaying()
        if let player = self.player {
            let current = player.currentTime()
            let currentTime = CGFloat(current.value) / CGFloat(current.timescale)
            let endTime = CGFloat(self.endTime.value) / CGFloat(self.endTime.timescale)
            if currentTime >= endTime {
                sender.invalidate()
                self.pause()
                self.player?.seek(to: self.startTime, completionHandler: { (_) in
                    self.delegate?.videoPlaying()
                })
            }
        }
    }

    func play() {
        guard let player = self.playerLayer.player else { return }
        player.play()
        self.timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: true)
        self.delegate?.videoPlaying()
    }

    func pause() {
        guard let player = self.playerLayer.player else { return }
        player.pause()
        self.timer?.invalidate()
        self.timer = nil
    }

    func invalidate() {
        self.timer?.invalidate()
        self.timer = nil
        guard let player = self.playerLayer.player else { return }
        if self.isPlaying {
            player.pause()
        }
    }

    func restoreCrop() {
        self.dimFrame = nil
    }
}

// MARK: VideoView + VideoViewType
extension VideoView {
    enum VideoViewType {
        case `default`
        case convert
    }
}

// MARK: VideoView + DimView
extension VideoView {
    class DimView: UIView {
        private var path: CGPath?

        init() {
            super.init(frame: .zero)
            self.isUserInteractionEnabled = false
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }

        func mask(_ path: CGPath, duration: TimeInterval, animated: Bool) {
            self.path = path
            if let mask = self.layer.mask as? CAShapeLayer {
                mask.removeAllAnimations()
                if animated {
                    let animation = CABasicAnimation(keyPath: "path")
                    animation.delegate = self
                    animation.fromValue = mask.path
                    animation.toValue = path
                    animation.byValue = path
                    animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                    animation.isRemovedOnCompletion = false
                    animation.fillMode = .forwards
                    animation.duration = duration
                    mask.add(animation, forKey: "path")
                } else {
                    mask.path = path
                }
            } else {
                let maskLayer = CAShapeLayer()
                maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
                maskLayer.backgroundColor = UIColor.clear.cgColor
                maskLayer.path = path
                self.layer.mask = maskLayer
            }
        }
    }
}

// MARK: VideoView.DimView + CAAnimationDelegate
extension VideoView.DimView: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let path = self.path else { return }
        if let mask = self.layer.mask as? CAShapeLayer {
            mask.removeAllAnimations()
            mask.path = path
        }
    }
}

//MIT License
//
//Copyright (c) 2020 Gwan-ho Kim <pikachu77769@gmail.com>
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

import UIKit
import AVKit

// MARK: VideoTrimDelegate
public protocol VideoTrimDelegate: class {
    func videoTrimStartTrimChange(_ videoTrim: VideoTrim)
    func videoTrimEndTrimChange(_ videoTrim: VideoTrim)
    func videoTrimPlayTimeChange(_ videoTrim: VideoTrim)
}

// MARK: VideoFrameView
open class VideoTrim: UIView {
    public weak var delegate: VideoTrimDelegate?

    // Number of Frame View Images
    public var frameImageCount = 20

    // Trim minimum length
    public var trimReaminWidth: CGFloat = 50

    public var topMargin: CGFloat = 0 {
        didSet {
            self.constraints.filter({ $0.identifier == "timeLabelTop" }).first?.constant = self.topMargin
        }
    }

    public var bottomMargin: CGFloat = 0 {
        didSet {
            self.constraints.filter({ $0.identifier == "frameContainerViewBottom" }).first?.constant = -self.bottomMargin - self.playLineVerticalSize
        }
    }

    public var leadingMargin: CGFloat = 14 {
        didSet {
            let constant = self.leadingMargin + self.trimLineWidth
            self.constraints.filter({ $0.identifier == "frameContainerViewLeading" }).first?.constant = constant
        }
    }

    public var trailingMargin: CGFloat = 14 {
        didSet {
            let constant = self.trailingMargin + self.trimLineWidth
            self.constraints.filter({ $0.identifier == "frameContainerViewTrailing" }).first?.constant = -constant
        }
    }

    public var frameHeight: CGFloat = 48 {
        didSet {
            self.frameContainerView.constraints.filter({ $0.identifier == "frameContainerViewHeight" }).first?.constant = self.frameHeight
        }
    }

    public var trimMaskDimViewColor: UIColor = UIColor(white: 0/255, alpha: 0.7) {
        didSet {
            self.trimStartTimeDimView.backgroundColor = self.trimMaskDimViewColor
            self.trimEndTimeDimView.backgroundColor = self.trimMaskDimViewColor
        }
    }

    public var trimLineRadius: CGFloat = 4 {
        didSet {
            self.trimLineView.layer.cornerRadius = self.trimLineRadius
        }
    }

    public var trimLineWidth: CGFloat = 4 {
        didSet {
            self.trimLineView.layer.borderWidth = self.trimLineWidth
            self.frameContainerView.constraints.filter({ $0.identifier == "frameViewTop" }).first?.constant = self.trimLineWidth
            self.frameContainerView.constraints.filter({ $0.identifier == "frameViewBottom" }).first?.constant = -self.trimLineWidth
            self.frameContainerView.constraints.filter({ $0.identifier == "trimLineViewLeading" }).first?.constant = -self.trimLineWidth
            self.frameContainerView.constraints.filter({ $0.identifier == "trimLineViewTriling" }).first?.constant = self.trimLineWidth

            let leadingMargin = self.leadingMargin
            self.leadingMargin = leadingMargin

            let trailingMargin = self.trailingMargin
            self.trailingMargin = trailingMargin
        }
    }

    public var playLineRadius: CGFloat = 3 {
        didSet {
            self.playTimeLineView.layer.cornerRadius = self.playLineRadius
        }
    }

    public var playLineWidth: CGFloat = 6 {
        didSet {
            self.playTimeLineView.constraints.filter({ $0.identifier == "playTimeLineViewWidth" }).first?.constant = self.playLineWidth
        }
    }

    public var playLineVerticalSize: CGFloat = 4 {
        didSet {
            self.frameContainerView.constraints.filter({ $0.identifier == "playTimeLineViewTop" }).first?.constant = -self.playLineVerticalSize
            self.frameContainerView.constraints.filter({ $0.identifier == "playTimeLineViewBottom" }).first?.constant = self.playLineVerticalSize
            let bottomMargin = self.bottomMargin
            self.bottomMargin = bottomMargin
        }
    }
    public var trimLineViewColor: CGColor = UIColor.white.cgColor {
        didSet {
            self.trimLineView.layer.borderColor = self.trimLineViewColor
        }
    }

    public var playTimeLineViewColor: UIColor = UIColor.white {
        didSet {
            self.playTimeLineView.backgroundColor = self.playTimeLineViewColor
        }
    }

    public var timeColor: UIColor = UIColor.white {
        didSet {
            self.timeLabel.textColor = self.timeColor
            self.totalTimeLabel.textColor = self.timeColor
        }
    }

    public var timeFont: UIFont = UIFont.systemFont(ofSize: 15) {
        didSet {
            self.timeLabel.font = self.timeFont
            self.totalTimeLabel.font = self.timeFont
        }
    }

    public var playTime: CMTime {
        guard let asset = self.asset,
            let leadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewLeading" }).first,
            let playTimeLineViewLeadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "playTimeLineViewLeading" }).first else { return .zero }
        let playTimeWidth = playTimeLineViewLeadingConstraint.constant - leadingConstraint.constant
        let duration = asset.duration
        let value = CGFloat(duration.value)
        let playTime = value * playTimeWidth / self.frameWidth
        return CMTime(value: CMTimeValue(playTime), timescale: duration.timescale)
    }

    public var startTime: CMTime {
        guard let asset = self.asset,
            let leadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewLeading" }).first else { return .zero }
        let startTimeWidth = leadingConstraint.constant
        let duration = asset.duration
        let value = CGFloat(duration.value)
        let startTime = value * startTimeWidth / self.frameWidth
        return CMTime(value: CMTimeValue(startTime), timescale: duration.timescale)
    }

    public var endTime: CMTime {
        return CMTime(value: CMTimeValue(CGFloat(self.startTime.value) + CGFloat(self.durationTime.value)), timescale: self.startTime.timescale)
    }

    public var durationTime: CMTime {
        guard let asset = self.asset,
            let leadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewLeading" }).first,
            let trilingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewTriling" }).first else { return .zero }
        let remainWidth = self.frameWidth - abs(leadingConstraint.constant) - abs(trilingConstraint.constant)
        let duration = asset.duration
        let value = CGFloat(duration.value)
        let endTime = value * remainWidth / self.frameWidth
        return CMTime(value: CMTimeValue(endTime), timescale: duration.timescale)
    }

    // asset
    open var asset: AVAsset? {
        didSet {
            self.updateLayout()
            if let asset = self.asset, asset.duration.value != 0 {
                self.timeLabel.isHidden = false
                self.totalTimeLabel.isHidden = false
                self.frameContainerView.isHidden = false
                self.trimStartTimeDimView.isHidden = false
                self.trimEndTimeDimView.isHidden = false
            } else {
                self.timeLabel.isHidden = true
                self.totalTimeLabel.isHidden = true
                self.frameContainerView.isHidden = true
                self.trimStartTimeDimView.isHidden = true
                self.trimEndTimeDimView.isHidden = true
            }
            self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewLeading" }).first?.constant = 0
            self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewTriling" }).first?.constant = 0
            self.frameContainerView.constraints.filter({ $0.identifier == "playTimeLineViewLeading" }).first?.constant = 0

            self.frameImages.forEach { (imageView) in
                imageView.image = nil
                imageView.showVisualEffect()
            }
            if let asset = self.asset {
                let duration = asset.duration
                let timescale = duration.timescale
                let timescaleValue = CGFloat(timescale)
                let totalTime = Int(ceil(CMTimeGetSeconds(duration)))

                DispatchQueue.global().async {
                    let imageGenerator = AVAssetImageGenerator(asset: asset)
                    imageGenerator.appliesPreferredTrackTransform = true

                    var extractionImages = [UIImage?]()
                    for index in 0..<self.frameImageCount {
                        let timeValue = (CGFloat(totalTime) * (CGFloat(index) / CGFloat(self.frameImageCount))) * timescaleValue
                        let time = CMTime(value: CMTimeValue(timeValue), timescale: timescale)
                        if let imageRef = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
                            let image = UIImage(cgImage: imageRef)
                            if index == 0 {
                                DispatchQueue.main.async {
                                    if self.asset == asset {
                                        self.frameImages.forEach({ $0.image = image })
                                    }
                                }
                            }
                            extractionImages.append(image)
                        }
                    }
                    DispatchQueue.main.async {
                        if self.asset == asset {
                            for (index, imageView) in self.frameImages.enumerated() {
                                if extractionImages.count > index {
                                    imageView.image = extractionImages[index]
                                }
                                imageView.hideVisualEffect()
                            }
                        }
                    }
                }
                self.timeLabel.text = 0.time
                self.totalTimeLabel.text = totalTime.time
            }
        }
    }

    // current time
    open var currentTime: CMTime? {
        didSet {
            guard let asset = self.asset,
                let current = self.currentTime,
                let leadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewLeading" }).first,
                let playTimeLineViewLeadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "playTimeLineViewLeading" }).first,
                let trilingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewTriling" }).first else { return }
            let totalTime = CGFloat(asset.duration.value) / CGFloat(asset.duration.timescale)
            let currentTime = CGFloat(current.value) / CGFloat(current.timescale)
            let percentage = currentTime / totalTime
            var leading = self.frameWidth * percentage
            if leading <= leadingConstraint.constant {
                leading = leadingConstraint.constant
            }
            if leading >= self.frameWidth - abs(trilingConstraint.constant) - self.playLineWidth {
                leading = self.frameWidth - abs(trilingConstraint.constant) - self.playLineWidth
            }
            playTimeLineViewLeadingConstraint.constant = leading
            self.updatePlayTime()
        }
    }

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0:00"
        return label
    }()

    private let totalTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0:00"
        return label
    }()

    private let frameContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let frameView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private lazy var frameImages: [VisualEffectImageView] = {
        var imageViews = [VisualEffectImageView]()
        for _ in 0..<self.frameImageCount {
            let imageView = VisualEffectImageView(frame: .zero)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = .clear
            imageView.clipsToBounds = true
            imageViews.append(imageView)
        }
        return imageViews
    }()

    private let trimLineContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let trimLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let trimStartTimeLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let trimEndTimeLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let trimStartTimeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let trimEndTimeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let trimStartTimeDimView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let trimEndTimeDimView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let playTimeLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let playTimeContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private var frameWidth: CGFloat {
        return self.frameContainerView.bounds.width
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.isUserInteractionEnabled = true
        self.clipsToBounds = true
        self.backgroundColor = .black

        self.timeLabel.isHidden = true
        self.totalTimeLabel.isHidden = true
        self.frameContainerView.isHidden = true
        self.trimStartTimeDimView.isHidden = true
        self.trimEndTimeDimView.isHidden = true

        self.addSubview(self.timeLabel)
        self.addSubview(self.totalTimeLabel)
        self.addSubview(self.frameContainerView)
        self.frameContainerView.addSubview(self.frameView)
        self.frameContainerView.addSubview(self.trimStartTimeDimView)
        self.frameContainerView.addSubview(self.trimEndTimeDimView)
        self.frameContainerView.addSubview(self.trimLineContainerView)
        self.frameContainerView.addSubview(self.trimLineView)
        self.frameContainerView.addSubview(self.trimStartTimeLineView)
        self.frameContainerView.addSubview(self.trimEndTimeLineView)
        self.frameContainerView.addSubview(self.trimStartTimeView)
        self.frameContainerView.addSubview(self.trimEndTimeView)
        self.frameContainerView.addSubview(self.playTimeLineView)
        self.frameContainerView.addSubview(self.playTimeContainerView)

        self.frameImages.forEach({ self.frameView.addSubview($0) })

        // timeLabel
        let timeLabelTopConstraint = NSLayoutConstraint(item: self.timeLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 10)
        timeLabelTopConstraint.identifier = "timeLabelTop"
        self.addConstraints([
            timeLabelTopConstraint
        ])

        // timeLabel & totalTimeLabel
        self.addConstraints([
            NSLayoutConstraint(item: self.timeLabel, attribute: .top, relatedBy: .equal, toItem: self.totalTimeLabel, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.timeLabel, attribute: .bottom, relatedBy: .equal, toItem: self.totalTimeLabel, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        // timeLabel & trimStartTimeLineView
        self.addConstraints([
            NSLayoutConstraint(item: self.timeLabel, attribute: .centerX, relatedBy: .equal, toItem: self.trimStartTimeLineView, attribute: .centerX, multiplier: 1, constant: 0)
        ])

        // totalTimeLabel & trimEndTimeView
        let totalTimeLabelCenterXConstraint = NSLayoutConstraint(item: self.totalTimeLabel, attribute: .centerX, relatedBy: .equal, toItem: self.trimEndTimeLineView, attribute: .centerX, multiplier: 1, constant: 0)
        totalTimeLabelCenterXConstraint.priority = UILayoutPriority(rawValue: 950)
        self.addConstraints([
            totalTimeLabelCenterXConstraint
        ])

        // timeLabel & frameContainerView
        self.addConstraints([
            NSLayoutConstraint(item: self.timeLabel, attribute: .bottom, relatedBy: .equal, toItem: self.frameContainerView, attribute: .top, multiplier: 1, constant: -6)
        ])

        // frameContainerView
        let frameContainerViewBottomConstraint = NSLayoutConstraint(item: self.frameContainerView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -16)
        frameContainerViewBottomConstraint.identifier = "frameContainerViewBottom"
        let frameContainerViewLeadingConstraint = NSLayoutConstraint(item: self.frameContainerView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 20)
        frameContainerViewLeadingConstraint.identifier = "frameContainerViewLeading"
        let frameContainerViewTrailingConstraint = NSLayoutConstraint(item: self.frameContainerView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -20)
        frameContainerViewTrailingConstraint.identifier = "frameContainerViewTrailing"
        self.addConstraints([
            frameContainerViewLeadingConstraint,
            frameContainerViewTrailingConstraint,
            frameContainerViewBottomConstraint
        ])

        // frameContainerView
        let frameContainerViewHeightConstraint = NSLayoutConstraint(item: self.frameContainerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 48)
        frameContainerViewHeightConstraint.identifier = "frameContainerViewHeight"
        self.frameContainerView.addConstraints([
            frameContainerViewHeightConstraint
        ])

        // frameView
        let frameViewTopConstraint = NSLayoutConstraint(item: self.frameView, attribute: .top, relatedBy: .equal, toItem: self.frameContainerView, attribute: .top, multiplier: 1, constant: 0)
        frameViewTopConstraint.identifier = "frameViewTop"
        let frameViewBottomConstraint = NSLayoutConstraint(item: self.frameView, attribute: .bottom, relatedBy: .equal, toItem: self.frameContainerView, attribute: .bottom, multiplier: 1, constant: 0)
        frameViewBottomConstraint.identifier = "frameViewBottom"
        self.frameContainerView.addConstraints([
            NSLayoutConstraint(item: self.frameView, attribute: .leading, relatedBy: .equal, toItem: self.frameContainerView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.frameView, attribute: .trailing, relatedBy: .equal, toItem: self.frameContainerView, attribute: .trailing, multiplier: 1, constant: 0),
            frameViewTopConstraint,
            frameViewBottomConstraint
        ])

        // trimLineContainerView
        let trimContainerViewLeadingConstraint = NSLayoutConstraint(item: self.trimLineContainerView, attribute: .leading, relatedBy: .equal, toItem: self.frameContainerView, attribute: .leading, multiplier: 1, constant: 0)
        trimContainerViewLeadingConstraint.identifier = "trimContainerViewLeading"
        let trimContainerViewTrilingConstraint = NSLayoutConstraint(item: self.trimLineContainerView, attribute: .trailing, relatedBy: .equal, toItem: self.frameContainerView, attribute: .trailing, multiplier: 1, constant: 0)
        trimContainerViewTrilingConstraint.identifier = "trimContainerViewTriling"
        self.frameContainerView.addConstraints([
            trimContainerViewLeadingConstraint,
            trimContainerViewTrilingConstraint,
            NSLayoutConstraint(item: self.trimLineContainerView, attribute: .top, relatedBy: .equal, toItem: self.frameContainerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimLineContainerView, attribute: .bottom, relatedBy: .equal, toItem: self.frameContainerView, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        // trimLineView
        let trimLineViewLeadingConstraint = NSLayoutConstraint(item: self.trimLineView, attribute: .leading, relatedBy: .equal, toItem: self.trimLineContainerView, attribute: .leading, multiplier: 1, constant: 0)
        trimLineViewLeadingConstraint.identifier = "trimLineViewLeading"
        let trimLineViewTrilingConstraint = NSLayoutConstraint(item: self.trimLineView, attribute: .trailing, relatedBy: .equal, toItem: self.trimLineContainerView, attribute: .trailing, multiplier: 1, constant: 0)
        trimLineViewTrilingConstraint.identifier = "trimLineViewTriling"
        self.frameContainerView.addConstraints([
            trimLineViewLeadingConstraint,
            trimLineViewTrilingConstraint,
            NSLayoutConstraint(item: self.trimLineView, attribute: .top, relatedBy: .equal, toItem: self.trimLineContainerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimLineView, attribute: .bottom, relatedBy: .equal, toItem: self.trimLineContainerView, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        // trimStartTimeLineView
        self.frameContainerView.addConstraints([
            NSLayoutConstraint(item: self.trimStartTimeLineView, attribute: .top, relatedBy: .equal, toItem: self.frameContainerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimStartTimeLineView, attribute: .bottom, relatedBy: .equal, toItem: self.frameContainerView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimStartTimeLineView, attribute: .leading, relatedBy: .equal, toItem: self.trimLineContainerView, attribute: .leading, multiplier: 1, constant: 0)
        ])

        // trimStartTimeLineView
        self.trimStartTimeLineView.addConstraints([
            NSLayoutConstraint(item: self.trimStartTimeLineView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 2)
        ])

        // trimEndTimeLineView
        self.frameContainerView.addConstraints([
            NSLayoutConstraint(item: self.trimEndTimeLineView, attribute: .top, relatedBy: .equal, toItem: self.frameContainerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimEndTimeLineView, attribute: .bottom, relatedBy: .equal, toItem: self.frameContainerView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimEndTimeLineView, attribute: .trailing, relatedBy: .equal, toItem: self.trimLineContainerView, attribute: .trailing, multiplier: 1, constant: 0)
        ])

        // trimEndTimeLineView
        self.trimEndTimeLineView.addConstraints([
            NSLayoutConstraint(item: self.trimEndTimeLineView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 2)
        ])

        // trimStartTimeView
        self.frameContainerView.addConstraints([
            NSLayoutConstraint(item: self.trimStartTimeView, attribute: .top, relatedBy: .equal, toItem: self.frameContainerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimStartTimeView, attribute: .bottom, relatedBy: .equal, toItem: self.frameContainerView, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        // trimStartTimeView
        self.trimStartTimeView.addConstraints([
            NSLayoutConstraint(item: self.trimStartTimeView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 80)
        ])

        // trimStartTimeView & trimLineContainerView
        self.frameContainerView.addConstraints([
            NSLayoutConstraint(item: self.trimStartTimeView, attribute: .leading, relatedBy: .equal, toItem: self.trimLineContainerView, attribute: .leading, multiplier: 1, constant: -60)
        ])

        // trimEndTimeView
        self.frameContainerView.addConstraints([
            NSLayoutConstraint(item: self.trimEndTimeView, attribute: .top, relatedBy: .equal, toItem: self.frameContainerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimEndTimeView, attribute: .bottom, relatedBy: .equal, toItem: self.frameContainerView, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        // trimEndTimeView
        self.trimEndTimeView.addConstraints([
            NSLayoutConstraint(item: self.trimEndTimeView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 80)
        ])

        // trimEndTimeView & trimLineContainerView
        self.frameContainerView.addConstraints([
            NSLayoutConstraint(item: self.trimEndTimeView, attribute: .trailing, relatedBy: .equal, toItem: self.trimLineContainerView, attribute: .trailing, multiplier: 1, constant: 60)
        ])

        // self.trimStartTimeDimView & frameView
        self.frameContainerView.addConstraints([
            NSLayoutConstraint(item: self.trimStartTimeDimView, attribute: .top, relatedBy: .equal, toItem: self.frameView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimStartTimeDimView, attribute: .bottom, relatedBy: .equal, toItem: self.frameView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimStartTimeDimView, attribute: .leading, relatedBy: .equal, toItem: self.frameView, attribute: .leading, multiplier: 1, constant: 0)
        ])

        // self.trimStartTimeDimView & trimLineContainerView
        self.frameContainerView.addConstraints([
            NSLayoutConstraint(item: self.trimStartTimeDimView, attribute: .trailing, relatedBy: .equal, toItem: self.trimLineContainerView, attribute: .leading, multiplier: 1, constant: 0)
        ])

        // self.trimEndTimeDimView & frameView
        self.frameContainerView.addConstraints([
            NSLayoutConstraint(item: self.trimEndTimeDimView, attribute: .top, relatedBy: .equal, toItem: self.frameView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimEndTimeDimView, attribute: .bottom, relatedBy: .equal, toItem: self.frameView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trimEndTimeDimView, attribute: .trailing, relatedBy: .equal, toItem: self.frameView, attribute: .trailing, multiplier: 1, constant: 0)
        ])

        // self.trimEndTimeDimView & trimLineContainerView
        self.frameContainerView.addConstraints([
            NSLayoutConstraint(item: self.trimEndTimeDimView, attribute: .leading, relatedBy: .equal, toItem: self.trimLineContainerView, attribute: .trailing, multiplier: 1, constant: 0)
        ])

        // playTimeLineView
        let playTimeLineViewLeadingConstraint = NSLayoutConstraint(item: self.playTimeLineView, attribute: .leading, relatedBy: .equal, toItem: self.frameContainerView, attribute: .leading, multiplier: 1, constant: 0)
        playTimeLineViewLeadingConstraint.identifier = "playTimeLineViewLeading"
        let playTimeLineViewTopConstraint = NSLayoutConstraint(item: self.playTimeLineView, attribute: .top, relatedBy: .equal, toItem: self.frameContainerView, attribute: .top, multiplier: 1, constant: -2)
        playTimeLineViewTopConstraint.identifier = "playTimeLineViewTop"
        let playTimeLineViewBottomConstraint = NSLayoutConstraint(item: self.playTimeLineView, attribute: .bottom, relatedBy: .equal, toItem: self.frameContainerView, attribute: .bottom, multiplier: 1, constant: 2)
        playTimeLineViewBottomConstraint.identifier = "playTimeLineViewBottom"
        self.frameContainerView.addConstraints([
            playTimeLineViewLeadingConstraint,
            playTimeLineViewTopConstraint,
            playTimeLineViewBottomConstraint
        ])

        // playTimeLineView
        let playTimeLineViewWidthConstraint = NSLayoutConstraint(item: self.playTimeLineView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 6)
        playTimeLineViewWidthConstraint.identifier = "playTimeLineViewWidth"
        self.playTimeLineView.addConstraints([
            playTimeLineViewWidthConstraint
        ])

        // playTimeContainerView
        self.frameContainerView.addConstraints([
            NSLayoutConstraint(item: self.playTimeContainerView, attribute: .top, relatedBy: .equal, toItem: self.playTimeLineView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playTimeContainerView, attribute: .bottom, relatedBy: .equal, toItem: self.playTimeLineView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playTimeContainerView, attribute: .centerX, relatedBy: .equal, toItem: self.playTimeLineView, attribute: .centerX, multiplier: 1, constant: 0)
        ])

        // playTimeContainerView
        self.playTimeContainerView.addConstraints([
            NSLayoutConstraint(item: self.playTimeContainerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 40)
        ])

        var beforeImage: UIImageView?
        for imageView in self.frameImages {
            if let beforeImage = beforeImage {
                self.frameView.addConstraints([
                    NSLayoutConstraint(item: imageView, attribute: .leading, relatedBy: .equal, toItem: beforeImage, attribute: .trailing, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: beforeImage, attribute: .width, multiplier: 1, constant: 0)
                ])
            } else {
                self.frameView.addConstraints([
                    NSLayoutConstraint(item: imageView, attribute: .leading, relatedBy: .equal, toItem: self.frameView, attribute: .leading, multiplier: 1, constant: 0)
                ])
            }
            self.frameView.addConstraints([
                NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: self.frameView, attribute: .top, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: self.frameView, attribute: .bottom, multiplier: 1, constant: 0)
            ])
            beforeImage = imageView
        }
        if let beforeImage = beforeImage {
            self.frameView.addConstraints([
                NSLayoutConstraint(item: beforeImage, attribute: .trailing, relatedBy: .equal, toItem: self.frameView, attribute: .trailing, multiplier: 1, constant: 0)
            ])
        }

        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.emptyAction(_:))))
        self.frameContainerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.emptyAction(_:))))
        self.trimStartTimeView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.trimStartTimeGesture(_:))))
        self.trimEndTimeView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.trimEndTimeGesture(_:))))
        self.playTimeContainerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.playTimeGesture(_:))))
        self.trimLineView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.frameTap(_:))))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateLayout() {
        let topMargin = self.topMargin
        self.topMargin = topMargin

        let bottomMargin = self.bottomMargin
        self.bottomMargin = bottomMargin

        let leadingMargin = self.leadingMargin
        self.leadingMargin = leadingMargin

        let trailingMargin = self.trailingMargin
        self.trailingMargin = trailingMargin

        let frameHeight = self.frameHeight
        self.frameHeight = frameHeight

        let trimMaskDimViewColor = self.trimMaskDimViewColor
        self.trimMaskDimViewColor = trimMaskDimViewColor

        let trimLineRadius = self.trimLineRadius
        self.trimLineRadius = trimLineRadius

        let trimLineWidth = self.trimLineWidth
        self.trimLineWidth = trimLineWidth

        let playLineRadius = self.playLineRadius
        self.playLineRadius = playLineRadius

        let playLineWidth = self.playLineWidth
        self.playLineWidth = playLineWidth

        let playLineVerticalSize = self.playLineVerticalSize
        self.playLineVerticalSize = playLineVerticalSize

        let trimLineViewColor = self.trimLineViewColor
        self.trimLineViewColor = trimLineViewColor

        let playTimeLineViewColor = self.playTimeLineViewColor
        self.playTimeLineViewColor = playTimeLineViewColor

        let timeColor = self.timeColor
        self.timeColor = timeColor

        let timeFont = self.timeFont
        self.timeFont = timeFont
    }

    @objc private func emptyAction(_ sender: Any?) { }

    @objc private func trimStartTimeGesture(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            self.delegate?.videoTrimStartTrimChange(self)
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            self.delegate?.videoTrimEndTrimChange(self)
        }
        let point = sender.location(in: self.frameContainerView)
        let leadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewLeading" }).first
        let constant = point.x
        let trilingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewTriling" }).first
        let remainWidth = self.frameWidth - abs((trilingConstraint?.constant ?? 0))
        if constant < 0 {
            leadingConstraint?.constant = 0
            self.updateTotalTime()
            self.updatePlayTime()
            return
        } else if (constant + self.trimLineWidth*2 + self.trimReaminWidth) > remainWidth {
            return
        }
        leadingConstraint?.constant = constant
        self.updateTotalTime()
        self.updatePlayTime()
        if let playTimeLineViewLeadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "playTimeLineViewLeading" }).first {
            if constant > playTimeLineViewLeadingConstraint.constant {
                playTimeLineViewLeadingConstraint.constant = constant
                self.updatePlayTime()
                self.delegate?.videoTrimPlayTimeChange(self)
            }
        }
    }

    @objc private func trimEndTimeGesture(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            self.delegate?.videoTrimStartTrimChange(self)
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            self.delegate?.videoTrimEndTrimChange(self)
        }
        let point = sender.location(in: self.frameContainerView)
        let trilingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewTriling" }).first
        let constant = -(self.frameWidth - point.x)
        let leadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewLeading" }).first
        let remainWidth = self.frameWidth - abs((leadingConstraint?.constant ?? 0))
        if constant > 0 {
            trilingConstraint?.constant = 0
            self.updateTotalTime()
            return
        } else if(abs(constant) + self.trimLineWidth*2 + self.trimReaminWidth) > remainWidth {
            return
        }
        trilingConstraint?.constant = constant
        self.updateTotalTime()
        if let playTimeLineViewLeadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "playTimeLineViewLeading" }).first {
            if (self.frameWidth - abs(constant) - self.playLineWidth) < playTimeLineViewLeadingConstraint.constant {
                playTimeLineViewLeadingConstraint.constant = self.frameWidth - abs(constant) - self.playLineWidth
                self.updatePlayTime()
                self.delegate?.videoTrimPlayTimeChange(self)
            }
        }
    }

    @objc private func playTimeGesture(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            self.delegate?.videoTrimStartTrimChange(self)
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            self.delegate?.videoTrimEndTrimChange(self)
        }
        if sender.state == .changed {
            let point = sender.location(in: self.frameContainerView)
            let playTimeLineViewLeadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "playTimeLineViewLeading" }).first
            let constant = point.x
            if let leadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewLeading" }).first, let trilingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "trimContainerViewTriling" }).first {
                if leadingConstraint.constant > constant {
                    playTimeLineViewLeadingConstraint?.constant = leadingConstraint.constant
                    self.updatePlayTime()
                    self.delegate?.videoTrimPlayTimeChange(self)
                    return
                } else if constant > self.frameWidth - abs(trilingConstraint.constant) - self.playLineWidth {
                    playTimeLineViewLeadingConstraint?.constant = self.frameWidth - abs(trilingConstraint.constant) - self.playLineWidth
                    self.updatePlayTime()
                    self.delegate?.videoTrimPlayTimeChange(self)
                    return
                }
            }
            playTimeLineViewLeadingConstraint?.constant = constant
            self.updatePlayTime()
            self.delegate?.videoTrimPlayTimeChange(self)
        }
    }

    @objc private func frameTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self.frameContainerView)
        let constant = point.x
        let playTimeLineViewLeadingConstraint = self.frameContainerView.constraints.filter({ $0.identifier == "playTimeLineViewLeading" }).first
        playTimeLineViewLeadingConstraint?.constant = constant + (self.playLineWidth / 2)
        self.updatePlayTime()
        self.delegate?.videoTrimPlayTimeChange(self)
    }

    private func updatePlayTime() {
        let time = self.playTime
        if time == .zero {
            self.timeLabel.text = 0.time
        }
        self.timeLabel.text = Int(ceil(CGFloat(time.value) / CGFloat(time.timescale))).time
    }

    private func updateTotalTime() {
        let time = self.durationTime
        if time == .zero {
            self.totalTimeLabel.text = 0.time
        }
        self.totalTimeLabel.text = Int(ceil(CGFloat(time.value) / CGFloat(time.timescale))).time
    }
}

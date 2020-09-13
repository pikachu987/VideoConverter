# VideoTrim


[![Version](https://img.shields.io/cocoapods/v/VideoTrim.svg?style=flat)](https://cocoapods.org/pods/VideoTrim)
[![License](https://img.shields.io/cocoapods/l/VideoTrim.svg?style=flat)](https://cocoapods.org/pods/VideoTrim)
[![Platform](https://img.shields.io/cocoapods/p/VideoTrim.svg?style=flat)](https://cocoapods.org/pods/VideoTrim)
[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)](https://developer.apple.com/swift/)

## Introduce

You can extract an image for each video frame as a video asset and set the start time and end time.

<br/>

### VideoTrim

<img src='./img/gif1.gif' width='200px'>

|-|-|
|---|---|
|<img src='./img/img1.png' width='200px'>|<img src='./img/img2.png' width='200px'>|

## Requirements

`VideoTrim` written in Swift 5.0. Compatible with iOS 8.0+

## Installation

VideoTrim is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'VideoTrim'
```

## Usage

```swift
import VideoTrim
```

```swift
let videoTrim = VideoTrim()
self.view.addSubview(videoTrim)
```

done!

<br><br><br>



### Property

Set Property

asset

```swift

videoTrim.asset = AVAsset(url: url) // After setting the asset, the image frame is extracted.

videoTrim.currentTime = CMTime(value: 0, timescale: 0) // The frame bar position changes with currentTime.

```

```swift

videoTrim.frameImageCount = 20 // Number of frame images
videoTrim.trimReaminWidth = 50 // Video trim minimum length

videoTrim.topMargin = 4 // The top margin of the screen.
videoTrim.bottomMargin = 8 // The bottom margin of the screen.
videoTrim.leadingMargin = 0 // The leading margin of the screen.
videoTrim.trailingMargin = 0 // The trailing margin of the screen.

videoTrim.frameHeight = 48 // The image frame height.

videoTrim.trimMaskDimViewColor = UIColor(white: 0/255, alpha: 0.7) // The color of the screen overlay outside the start time and end time.
videoTrim.trimLineRadius = 4 // The radius of the trim line.
videoTrim.trimLineWidth = 4 // Border width of the trim line.
videoTrim.trimLineViewColor = UIColor.white.cgColor // This is the trim line color.

videoTrim.playLineRadius = 3 // The radius of the play line.
videoTrim.playLineWidth = 6 // This is the border width of the play line.
videoTrim.playLineVerticalSize = 4 // The difference between the height of the play line and the top and bottom of the image frame.
videoTrim.playTimeLineViewColor = UIColor.white // This is the play time line color.

videoTrim.timeColor = UIColor.white // time text color.
videoTrim.timeFont = UIFont.systemFont(ofSize: 15) // time text font.

```

Get Property

```swift

videoTrim.playTime // CMTime of PlayTime.
videoTrim.startTime // CMTime of start time.
videoTrim.endTime // CMTime of end time.
videoTrim.durationTime // CMTime from start time to end time.

```

<br><br>

### Delegate

```swift

class ViewController: UIViewController{
    override func viewDidLoad() {
        super.viewDidLoad()

        let videoTrim = VideoTrim()
        videoTrim.delegate = self
    }
}

// MARK: VideoTrimDelegate
extension ViewController: VideoTrimDelegate {
    func videoTrimStartTrimChange(_ videoTrim: VideoTrim) { // It is called when you touch the start time, end time, and play time.
        
    }

    func videoTrimEndTrimChange(_ videoTrim: VideoTrim) { // Called at the end of touch start time, end time and play time.
        
    }

    func videoTrimPlayTimeChange(_ videoTrim: VideoTrim) { // Called when touching the start time, end time and play time.
        
    }
}

```


## Author

pikachu987, pikachu77769@gmail.com

## License

VideoTrim is available under the MIT license. See the LICENSE file for more info.

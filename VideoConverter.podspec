#
# Be sure to run `pod lib lint VideoConverter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'VideoConverter'
  s.version          = '0.1.5'
  s.summary          = 'Video Crop, Rotate, Trim, Mute'
  s.description      = <<-DESC
Video can be cropped by x, y, width, and height, and can be rotated 0, 90, 180, 270 degrees.
And you can adjust the duration of video playback with startTime and endTime or durationTime, and you can also mute mode.
                       DESC
  s.homepage         = 'https://github.com/pikachu987/VideoConverter'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'pikachu987' => 'pikachu77769@gmail.com' }
  s.source           = { :git => 'https://github.com/pikachu987/VideoConverter.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'VideoConverter/Classes/**/*'
  s.swift_version = '5.0'
end

# Verizon Video Partner SDK Tutorials

This document will link you to sample projects and code, that are kept up-to-date with the latest versions of the the developer tools, API, and language we support. Our iOS and tvOS samples use CocoaPods as the default dependency manager (except for any Carthage-specific samples). 

- [Verizon Video Partner SDK Tutorials](#verizon-video-partner-sdk-tutorials)
	- [TLDR: Quick Start](#tldr-quick-start)
	- [Tutorial 1: Playing Videos](#tutorial-1-playing-videos)
        - [Create player](#create-player)
        - [Playing with AutoPlay on/off](#playing-with-autoplay-onoff)
		- [Playing Muted](#playing-muted)
        - [Disabling HLS (or forcing MP4 playback)](#disabling-hls-or-forcing-mp4-playback)
	- [Tutorial 2: Customizing the Default Controls UX](#tutorial-2-customizing-the-default-controls-ux)
        - [Setting default player controls’ tint color](#setting-default-player-controls-tint-color)
		- [Hiding Various Controls buttons](#hiding-various-controls-buttons)
		- [Closed Captioning / SAP Settings button](#closed-captioning--sap-settings-button)
		- [Using the 4 Custom Sidebar buttons](#using-the-4-custom-sidebar-buttons)
		- [Setting the LIVE indicator’s tint color](#setting-the-live-indicators-tint-color)
		- [Animations Customization and Disabling](#animations-customization-and-disabling)
        - [Custom Colors for Seeker Elements](#custom-colors-for-seeker-elements)
	- [Tutorial 3: Observing the Player](#tutorial-3-observing-the-player)
        - [Current Playback State and Position](#current-playback-state-and-position)
        - [Looping Playback](#looping-playback)
		- [LIVE, VOD, or 360°?](#live-vod-360)
        - [Manually Hooking up Previous or Next Videos](#manually-hooking-up-previous-or-next-videos)
	- [Tutorial 4: Error Handling in the SDK](#tutorial-4-error-handling-in-the-sdk)
		- [SDK Initialization Errors](#sdk-initialization-errors)
		- [Player Initialization Errors](#player-initialization-errors)      
        - [Restricted, Invalid or Deleted Videos](#restricted-invalid-or-deleted-videos)
	- [Tutorial 5: Specific Notes for tvOS Apps](#tutorial-5-specific-notes-for-tvos-apps)
		- [Playing Videos on tvOS](#playing-videos-on-tvos)
	- [Tutorial 6: Specific Notes for iPhone X](#tutorial-6-specific-notes-for-iphone-x)
		- [Player Controls on the iPhone X](#player-controls-on-the-iphone-x)
        - [Home Indicator Auto Hidden setup](#home-indicator-auto-hidden-setup)
        - [What You Must Do to Enable this Auto-Hiding Behavior in your App](#what-you-must-do-to-enable-this-auto-hiding-behavior-in-your-app)
	- [Next Steps](#next-steps)
		- [Getting Video/Playlist IDs into your apps](#getting-videoplaylist-ids-into-your-apps)
		- [Controlling Ads via your Portal Account](#controlling-ads-via-your-portal-account)
	- [FAQ](#faq)
		- [iOS hardware ringer](#ios-hardware-ringer)
		- [Extracting SDK version in runtime](#extracting-sdk-version-in-runtime)
    

<a name="tldr"></a>
## TLDR: Quick Start

Please, use tutorials inside this repository to get started. 
The complexity of tutorial is increasing with its number :) 
So for beginning use Tutorial 1!

<a name="tutorial-1"></a>
## Tutorial 1: Playing videos

### Create player

This tutorial sample shows you how to quickly init the VVPSDK and play videos using all the default options and behaviors, with very little code. Playing a single video, a list of individual videos, or videos from a Playlist are all done the same way. The only difference between playing a single video or multiple videos is that the SDK strings multiple videos together, connects up the previous and next player controls UX buttons, and if AutoPlay is on - plays them straight through.

#### _Tutorial Sample:_

> [Play single video](sources/Tutorial/Players.swift#L7)

> [Play array of videos](sources/Tutorial/Players.swift#L13)

### Playing with AutoPlay on/off

By default, the SDK plays videos with AutoPlay mode on. This means, that as soon as you construct a `Player`, the first video queues to play immediately (first, calling for an ad, of course). In this case, no further user action is required. As soon as the ad or the video is ready to play, it will. To override this behavior and turn off AutoPlay, look for the alternate way to construct the `Player` in this sample.s

If AutoPlay mode is off, the user will have to tap the play button to start the playback process. Alternatively, you can programmatically do this by controlling the Player object.

#### _Tutorial Sample:_

> [Turning Off AutoPlay](sources/Tutorial/Players.swift#L31)


### Playing Muted

You can easily control the mute state of the `Player` object. In this sample, you’ll find a code block that shows you how to set the mute state of the `Player` object.

#### _Tutorial Sample:_

> [Controlling Mute State](sources/Tutorial/Players.swift#L26)

### Disabling HLS (or forcing MP4 playback)

Most (but not all) of the videos in the Verizon Video Partner network, have multiple renditions. There may be some set of circumstances where you do not want to use HLS (M3U8) renditions, and therefore, want to force the alternate high resolution MP4 rendition. As a result, our SDK has the ability to override or disable getting the default HLS rendition. On iOS and tvOS, this is not something that we specifically advocate, so we won't show you this code in this tutorial. If you believe you have a good need for avoiding the network and visual performance improvements that HLS provides, please email [Video Support Team](mailto:video.support@oath.com) and we will be happy to help you!

<a name="tutorial-2"></a>
## Tutorial 2: Customizing the Default Controls UX

This tutorial sample shows you how to further modify the default controls UX.

### Setting default player controls’ tint color

The built-in tint color of the default video player controls UX is pink/magenta. This is deliberate. You set the tint color of the default player controls by setting the UIViewController’s tintColor. This can be done programmatically or via Interface Builder (IB) in Xcode, for your UIViewController, if you’re instantiating your view that way. In this sample, you’ll find a code block that shows you how to override the default controls color.

#### _Tutorial Sample:_

> [Overriding Default Tint Color](sources/Tutorial/PlayerViewControllerWrapper.swift#L103)

### Hiding Various Controls buttons

You can change the look of the default controls UX on a player-by-player basis to suit your app design needs. The elements that can be hidden include:
* ± 10 second skip buttons
* Previous and Next buttons
* Seekbar
* Video title
* Elapsed time
* Video duration
* Closed Captioning/SAP Settings button
* Picture-in-Picture (PiP) button
* AirPlay button

If you hide the title, and bottom element buttons such as CC/SAP, PiP, and AirPlay, the seekbar will fall down closer to the bottom of the video frame, to cover the gap usually left for those elements. See this tutorial for examples of how to hide/show these elements.

#### _Tutorial Sample:_

> [Hiding Default Controls Buttons](sources/Tutorial/PlayerViewControllerWrapper.swift#L157)


### Closed Captioning / SAP Settings button

This new feature of the VVPSDK is generally dependent on having this information in the HLS stream. There are ways to filter out what CC languages and SAP audio tracks are available. Also, there’s a way to control what the choices are for a given video. One reason to control this may be to implement a “sticky” closed captioning setting. By default, turning CC on only applies the the current playing video. A next or previous video would not have CC on by default. If you wanted your app to support a sticky setting for this, you would do it yourself. This part of this tutorial will show you how to accomplish this.

#### _Tutorial Sample:_

> [Filtered Subtitles](sources/Tutorial/PlayerViewControllerWrapper.swift#L163)


### Using the 4 Custom Sidebar buttons

Use this sample to see how to add custom code and behaviors to one of the 4 sidebar buttons. The Sidebar buttons are part of the default player controls UX and are there for you to add up to 4 different overlays/behaviors to your player. You provide the button graphics – icons for normal, selected, and highlighted modes, and you provide a handler to be called in the case of a button tap. The SDK will handle showing/hiding the buttons along with the other player controls.

#### _Tutorial Sample:_

> [Custom Sidebar Buttons](sources/Tutorial/SetupTutorials.swift#L32)

### Setting the LIVE indicator’s tint color

The LIVE indicator only appears during a LIVE streaming video playback. This will not appear for a video on demand video. Part of the LIVE indicator is the ability to colorize the • that appears next to the LIVE indicator. In general, you may want to use a standard pure-red color. However, it’s possible that you want to use your app’s brand color or while here instead. You can use black or any dark-gray color, but that is ill advised, because of the general nature of video to have lots of blacks in it. The sample code in this example shows how to set this.

#### _Tutorial Sample:_

> [LIVE Indicator Color](sources/Tutorial/PlayerViewControllerWrapper.swift#L154)


### Animations Customization and Disabling

We've added some new animations to our default player controls UX. If you want to change the animation duration, or disable the animations, you can. The sample code in this example shows how to turn off these animations as well as how to change the animation duration.

#### _Tutorial Sample:_

> [Animations Disabling](sources/Tutorial/PlayerViewControllerWrapper.swift#L170)

> [Animations Duration](sources/Tutorial/PlayerViewControllerWrapper.swift#L81)

### Custom Colors for Seeker Elements

The SDK also includes a feature to set custom colors for each element of player's seeker, like current time, progress, cue points etc. It is also possible to set custom color only for one of seeker elements, when the others will have the same color as the view's tint color.

#### _Tutorial Sample:_

> [Custom colors for seeker elements](sources/Tutorial/PlayerViewControllerWrapper.swift#L177)

<a name="tutorial-3"></a>
## Tutorial 3: Observing the Player

This tutorial sample shows you how to observe just about everything you can observe from VVPSDK `Player` objects. As you would suspect, many properties that can be observed, can also be set or manipulated.

### Current Playback State and Position

Determining the current state of the `Player` is a key need for apps … most app-level video playback logic starts here. In addition to the play/pause state, also includes the current position. Once you can query for these property values, you can also programmatically modify them.

#### _Tutorial Sample:_

> [Observe Player Properties](sources/Tutorial/PlayerViewControllerWrapper.swift#L236)

### Looping Playback

If your app has some need to loop a `Player` (one video or many), such as running a kiosk-style interface, for example. This is an easy operation to accomplish with the VVPSDK. Look in this example, to see how to determine when playback finishes, and how to reset the video index back to the first video and start it over.

#### _Tutorial Sample:_

> [Looping Videos](sources/Tutorial/PlayerViewControllerWrapper.swift#L62)

<a name="live-vod-360"></a>
### LIVE, VOD, or 360°?

You may need to inspect some more metadata on the video, such as what type of video this is – LIVE, video on demand, or 360°. This tutorial sample shows how to inspect this. You may need to make certain app design or UX decisions accordingly, based on the type of video that’s currently playing.

#### _Tutorial Sample:_

> [LIVE, VOD or 360](sources/Tutorial/PlayerViewControllerWrapper.swift#L120)

### Manually Hooking up Previous or Next Videos

There are many legitimate app UX circumstance, that can dictate the dynamicness of a video player – meaning, that not every app design will simply be setup to operate off fixed playlists or lists of videos. As such, the Player can be modified on the fly to dynamically handle what video is played when the previous or next buttons are tapped. This example tutorial has sample code that shows you precisely how to do this. However, be judicious with the usage of this behavior, and make sure it matches a natural flow of content for the user.

#### _Tutorial Sample:_

> [Hooking Up Next and Prev Videos](sources/Tutorial/PlayerViewControllerWrapper.swift#L185)

<a name="tutorial-4"></a>
## Tutorial 4: Error Handling in the SDK

This tutorial sample shows you how to handle various different types of errors that can occur when using the VVPSDK and how to catch and identify them. How you handle these in your app is up to you. The SDK is designed to either return a valid SDK or Player instance otherwise it returns an error. There is no middle ground. If you don’t get a valid instance, you should look at the error result instead to determine why. This section describes some common issues.

### SDK Initialization Errors

For various reasons, the SDK may fail to initialize. The most common reason for this, is you’re trying to use the VVPSDK without first having [onboarded your app’s bundle ID](/README.md#onboard-your-apps-for-sdk-authentication). In this case, you’ll get an error that looks like something like this:
```
{
	"error": "Not found - com.company.ungregisteredapp"
} 
```

#### _Tutorial Sample:_

> [SDK Error Handling](sources/Tutorial/PlayerViewControllerWrapper.swift#L55)

### Player Initialization Errors

For various reasons, the `Player` and `VVPSDK` may fail to initialize. Errors are usually self-descriptive. 
Contact [Video Support Team](mailto:video.support@oath.com) if you are stuck and we will be happy to help you!

#### _Tutorial Sample:_

> [Player Error Handling](sources/Tutorial/PlayerViewControllerWrapper.swift#L259)

### Restricted, Invalid or Deleted Videos

Videos can be `restricted` for playback in two very distinct ways. The first is geo restricted content. The second is device restricted content. If you’re attempting to initialize a `Player` with content that’s restricted against your device or geolocation, that content is automatically filtered out. Only valid, playable video IDs are accepted, and have their metadata pulled into the `Player` instance. If you end up with no `Player` instance, it’s because there are no valid video IDs for it to operate on. So, you get an error to this effect.

Videos can be `deleted` by the content owners, for a multitude of reasons including being removed for legal or copyright violations. If you’re attempting to initialize a `Player` with content that represents deleted videos, that content is also filtered out. Only valid, playable video IDs are accepted, and have their metadata pulled into the `Player` instance. If you end up with no `Player` instance, it’s because there are no valid video IDs for it to operate on. So, you get an error to this effect.

Videos can be `invalid` if you pass some ID that is incorrect, invalid, or unknown. Only valid, playable video IDs are accepted, and have their metadata pulled into the `Player` instance. If you end up with no `Player` instance, it’s because there are no valid video IDs for it to operate on. 

This tutorial sample shows how to detect that a video is not playable because one of those reasons and how to ovveride the message that will be shown in player.

#### _Tutorial Sample:_

> [Custom message for unplayable video](sources/Tutorial/PlayerViewControllerWrapper.swift#L148)

<a name="tutorial-5"></a>
## Tutorial 5: Specific Notes for tvOS Apps

The VVPSDK supports tvOS with the same source framework as iOS. We are utilising `AVPlayerViewController` for both content and advertisement playback. Controls also used from this class. As expected - no customisation of UI is allowed for tvOS implementation.

Because there is no way to tap on the screen, you cannot access the ad URL. Additionally, tvOS has no support for web views – so there would be no consistent way to render the ad URL.

### Playing Videos on tvOS

This tutorial sample shows you how to do many of the same things as iOS as described above in [Tutorial 1](#tutorial-1), but for tvOS. In terms of the VVPSDK, the biggest difference is that you cannot use the default Custom Controls UX with tvOS – you must use the built-in `AVPlayerViewController` controls. With this, you get direct access to the advanced Siri Remote control features, for example.

#### _Tutorial Sample:_

> [Playing Videos on tvOS](sources/Tutorial_tvOS/SystemPlayerViewControllerWrapper.swift)

## Tutorial 6: Specific Notes for iPhone X

### Player Controls on the iPhone X

The VVPSDK also supports the iPhone X. Video, thumbnail and shadow are stretched to the entire view, when main controls and LIVE indicator are limited by the safe area.

|Portrait|
|--------|
|<img width="340" alt="new-port" src="https://user-images.githubusercontent.com/31652265/36854565-feaaf04e-1d79-11e8-9db0-5359cc2ac0fe.png"> <img width="340" alt="newad-port" src="https://user-images.githubusercontent.com/31652265/36856781-82ec2724-1d7f-11e8-9124-05000b2355ab.png">|

|Landscape|
|--------|
|<img width="650" alt="new-land" src="https://user-images.githubusercontent.com/31652265/36854733-5b511dbe-1d7a-11e8-8c2b-b47d16238b36.png">
<img width="650" alt="newad-land" src="https://user-images.githubusercontent.com/31652265/36856788-8775270a-1d7f-11e8-8fa9-c375fd0b546b.png">|

### Home Indicator Auto Hidden setup

One of the most important changes in iPhone X is that it doesn't have Home Button anymore. It was replaced with a Home Indicator - a small horizontal bar on the bottom of the screen. It is obvious that no one wants to see that indicator showing while the video is playing (especially in full-screen), so we've added logic to our default controls UX that will turn on 'Home Indicator Auto Hidden' mode after our controls are hidden.

### What You Must Do to Enable this Auto-Hiding Behavior in your App

To implement this desired behavior, in the main view controller that contains the `Player` object, you should override the default `childViewControllerForHomeIndicatorAutoHidden` method of `UIViewController`, which has to return the `defaultControlsViewController`. If you don't add that method to your controller, it wouldn't use our implementation, so you will be able to control it on your own.

To see how it works, simply launch our Tutorials app on an iPhone X and play any video.

#### _Tutorial Sample:_

> [Adding Method Override to Support iPhone X](Tutorials/Tutorial)


## Next Steps 

### Getting Video/Playlist IDs into your apps

The VVPSDK operates on Verizon Video Partner network video and playlist IDs. That said, it is the application’s responsibility to dynamically acquire video IDs and/or playlist IDs either via your own CMS (content management system) or perhaps via a direct Search API call. Since apps are generally dynamic in their content (video or otherwise), you need to figure out how to deliver these content IDs into your app, so they can be passed to the SDK to play against. Although unadvised, the easiest possible approach is to hardcode one or more playlist ID[s] into an app, and let those playlists dynamically change their content via the Verizon Video Partner network Portal. The upside to this is you don’t need a CMS or further server communications on your end to get video information into your app, and thus to the SDK. The downside, is that if any of those IDs are ever deleted, the app will virtually be useless in terms of video playback.

For more information about the Search API, the Verizon Video Partner network Portal, or creation and manipulation of playlists, please email the [Video Support Team](mailto:video.support@oath.com).

### Controlling Ads via your Portal Account

You have some options with respect to ads and the VVPSDK. During early development, your developers are going to want ads disabled because they’re intrusive to the development process, and unnecessary. Before you launch, you will likely want to see test or Public Service Announcement (PSA) ads enabled all the time, so you can get a feel for how ads will impact your users in various parts of your app. And, as you launch, you’ll want to enable live production ads for your app, so you’re ready to go as soon as your app passes through the App Store submission process.

To make changes to the ads settings for your app, please contact [Video Support Team](mailto:video.support@oath.com) and they’ll promptly assist you.

## FAQ

### iOS Hardware Ringer

By default the hardware ringer position (muted/unmuted) is respected - if it is in muted state the video will play without sound.
To override this behavior you need to add following code before creating a player. 
This needs to be done only once - for example this in `AppDelegate` class.

```swift
let audioSession = AVAudioSession.sharedInstance()
do {
    try audioSession.setCategory(AVAudioSessionCategoryPlayback)
} catch {
    assertionFailure("Audio session `setCategory` failed!")
}
```

Details about this category can be found [here](https://developer.apple.com/documentation/avfoundation/avaudiosessioncategoryplayback?language=objc).

### Extracting SDK version in runtime

If you are looking for SDK version in runtime - here is the code snippet that will extract it:

```swift
let version = VVPSDK.version // "1.1.0"
``````

//  Copyright 2018, Oath Inc.
//  Licensed under the terms of the MIT License. See LICENSE.md file in project root for terms.

import Foundation
import PlayerCore
import CoreMedia

extension TrackingPixels.Connector {
    func process(state: PlayerCore.State, model: PlayerCore.Model) {
        guard let item = model.playlist[state.playlist.currentIndex].available else { return }
        var openMeasurementAdEvents: PlayerCore.OpenMeasurement.AdEvents?
        var openMeasurementVideoEvents: PlayerCore.OpenMeasurement.VideoEvents?
        switch state.openMeasurement {
        case .active(let adEvents, let videoEvents):
            openMeasurementAdEvents = adEvents
            openMeasurementVideoEvents = videoEvents
        case .finished(let adEvents, let videoEvents):
            openMeasurementAdEvents = adEvents
            openMeasurementVideoEvents = videoEvents
        default: break
        }
        let adType: Ad.Metrics.PlayType = perform {
            switch state.ad.currentType {
            case .preroll: return .preroll
            case .midroll: return .midroll
            }
        }
        
        vrmDetector.process(state: state.adVRMManager).forEach { result in
            switch result {
            case .completeRequest(let complete):
                reporter.adVRMRequest(videoIndex: state.playlist.currentIndex,
                                      type: adType,
                                      sequenceNumber: state.adVRMManager.requestsFired,
                                      transactionId: complete.transactionID,
                                      videoViewUID: state.playbackSession.id.uuidString)
            case .startItem(let start):
                reporter.adEngineRequest(videoIndex: state.playlist.currentIndex,
                                         info: VerizonVideoPartnerSDK.info(from: start.info),
                                         type: adType,
                                         transactionId: start.transactionID,
                                         videoViewUID: state.playbackSession.id.uuidString)
                reporter.adServerRequest(info: VerizonVideoPartnerSDK.info(from: start.info),
                                         videoIndex: state.playlist.currentIndex,
                                         videoViewUID: state.playbackSession.id.uuidString)
                
            case .completeItem(let item):
                reporter.adEngineResponse(videoIndex: state.playlist.currentIndex,
                                          info: VerizonVideoPartnerSDK.info(from: item.info),
                                          type: adType,
                                          responseStatus: .yes,
                                          responseTime: UInt(item.responseTime),
                                          timeout: item.timeoutBarrier,
                                          fillType: item.fillType,
                                          transactionId: item.transactionID,
                                          videoViewUID: state.playbackSession.id.uuidString)
            case .timeoutItem(let timeout):
                reporter.adEngineResponse(videoIndex: state.playlist.currentIndex,
                                          info: VerizonVideoPartnerSDK.info(from: timeout.info),
                                          type: adType,
                                          responseStatus: .timeout,
                                          responseTime: UInt(timeout.responseTime),
                                          timeout: timeout.timeoutBarrier,
                                          fillType: timeout.fillType,
                                          transactionId: timeout.transactionID,
                                          videoViewUID: state.playbackSession.id.uuidString)
            case .otherErrorItem(let other):
                reporter.adEngineResponse(videoIndex: state.playlist.currentIndex,
                                          info: VerizonVideoPartnerSDK.info(from: other.info),
                                          type: adType,
                                          responseStatus: .no,
                                          responseTime: UInt(other.responseTime),
                                          timeout: nil,
                                          fillType: other.fillType,
                                          transactionId: other.transactionID,
                                          videoViewUID: state.playbackSession.id.uuidString)
            }
        }
        struct Payload {
            let info: Ad.Metrics.Info
            let transactionID: String?
            let adID: String?
            let slot: String
            let pixels: PlayerCore.AdPixels
        }
        func engineFlow(stage: Ad.Metrics.ExecutionStage, payload: Payload) {
            reporter.adEngineFlow(videoIndex: state.playlist.currentIndex,
                                  info: payload.info,
                                  type: adType,
                                  stage: stage,
                                  width: state.viewport.dimensions?.width,
                                  height: state.viewport.dimensions?.height,
                                  autoplay: model.isAutoplayEnabled,
                                  transactionId: payload.transactionID,
                                  adId: payload.adID,
                                  videoViewUID: state.playbackSession.id.uuidString)
        }
        
        func report(with function: (Payload) -> ()) {
            guard
                case .finish(let finish) = state.adVRMManager.request.state,
                let completeItem = finish.completeItem else { return }
            let info = VerizonVideoPartnerSDK.info(from: completeItem.info)
            
            func pixels() -> PlayerCore.AdPixels {
                if let pixels = state.adInfoHolder?.pixels {
                    return .init(impression: pixels.impression,
                                 error: pixels.error,
                                 clickTracking: pixels.clickTracking,
                                 creativeView: pixels.creativeView,
                                 start: pixels.start,
                                 firstQuartile: pixels.firstQuartile,
                                 midpoint: pixels.midpoint,
                                 thirdQuartile: pixels.thirdQuartile,
                                 complete: pixels.complete,
                                 pause: pixels.pause,
                                 resume: pixels.resume,
                                 skip: pixels.skip,
                                 mute: pixels.mute,
                                 unmute: pixels.unmute,
                                 acceptInvitation: pixels.acceptInvitation,
                                 acceptInvitationLinear: pixels.acceptInvitationLinear,
                                 close: pixels.close,
                                 closeLinear: pixels.closeLinear,
                                 collapse: pixels.collapse)
                } else {
                    fatalError("No pixels which are required to fire!")
                }
            }
            function(Payload(info: info,
                             transactionID: completeItem.transactionID,
                             adID: completeItem.adId,
                             slot: finish.slot,
                             pixels: pixels()))
        }
        
        /* Ad View Time Detector */ do {
            let input = Detectors.AdViewTime.Input(
                duration: state.duration.ad?.seconds,
                currentTime: state.currentTime.ad.seconds,
                isAdFinished: state.adTracker.isFinished,
                isSessionCompleted: state.playerSession.isCompleted,
                videoIndex: state.playlist.currentIndex,
                vvuid: state.playbackSession.id.uuidString)
            
            if let result = adViewTimeDetector.process(newInput: input) {
                guard let holder = state.adInfoHolder else { return }
                let info = VerizonVideoPartnerSDK.info(from: holder.info)
                reporter.adViewTime(videoIndex: result.videoIndex,
                                    info: info,
                                    type: adType,
                                    videoViewUID: result.vvuid,
                                    adId: holder.adID,
                                    transactionId: state.transactionIDHolder?.transactionID,
                                    adCurrentTime: result.time,
                                    adDuration: result.duration)
            }
        }
        /* Slot Opportunity Detector */ do {
            if let adSessionID = state.adVRMManager.request.id {
                let slotDetected = adSlotOpportunityDetector.process(
                    sessionID: adSessionID,
                    adPlaying: state.rate.adRate.stream,
                    adSkipped: perform {
                        guard case .skipped = state.adVRMManager.request.state else { return false }
                        return true },
                    adFailed: perform {
                        guard case .failed = state.adVRMManager.request.state else { return false }
                        return true },
                    contentPlaying: state.rate.contentRate.stream)
                if slotDetected, let result = state.adVRMManager.request.result {
                    reporter.slotOpportunity(videoIndex: state.playlist.currentIndex,
                                             slot: result.slot,
                                             transactionId: result.transactionID,
                                             width: state.viewport.dimensions?.width ?? 0,
                                             videoViewUID: state.playbackSession.id.uuidString,
                                             type: adType)
                }
            }
        }
        /* User Actions Detector */ do {
            let action: Detectors.UserActions.PossibleActions
            switch state.userActions {
            case .play: action = .play
            case .pause: action = .pause
            case .nothing: action = .nothing
            }
            let result = adUserActionsDetector.render(hasTime: state.duration.ad != nil,
                                                      action: action)
            switch result {
            case .didPlay:
                report { payload in
                    reporter.sendBeacon(urls: payload.pixels.resume)
                }
                openMeasurementVideoEvents?.resume()
            case .didPause:
                report { payload in
                    reporter.sendBeacon(urls: payload.pixels.pause)
                }
                openMeasurementVideoEvents?.pause()
            case .nothing: break
            }
        }
        
        /*Ad Max Show Time Detector*/ do {
            if adMaxShowTimerDetector.process(state: state) {
                guard let holder = state.adInfoHolder else { return }
                let info = VerizonVideoPartnerSDK.info(from: holder.info)
                reporter.adEngineFlow(videoIndex: state.playlist.currentIndex,
                                      info: info,
                                      type: adType,
                                      stage: .killed,
                                      width: state.viewport.dimensions?.width,
                                      height: state.viewport.dimensions?.height,
                                      autoplay: model.isAutoplayEnabled,
                                      transactionId: state.transactionIDHolder?.transactionID,
                                      adId: holder.adID,
                                      videoViewUID: state.playbackSession.id.uuidString)
            }
        }
        
        switch state.ad.adCreative {
        case .vpaid:
            let events = vpaidEventsDetector.process(events: state.vpaid.events)
            guard !events.isEmpty else { return }
            guard let holder = state.adInfoHolder else { return }
            let info = VerizonVideoPartnerSDK.info(from: holder.info)
            events.forEach {
                switch $0 {
                case .AdScriptLoaded:
                    report { payload in
                        engineFlow(stage: .loaded, payload: payload)
                    }
                case .AdSkipped:
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.skip)
                        engineFlow(stage: .skipped, payload: payload)
                    }
                case .AdImpression:
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.impression)
                        engineFlow(stage: .started, payload: payload)
                        engineFlow(stage: .win, payload: payload)
                    }
                case .AdUserAcceptInvitation:
                    report { payload in
                        if payload.pixels.acceptInvitationLinear.isEmpty {
                            reporter.sendBeacon(urls: payload.pixels.acceptInvitation)
                        } else {
                            reporter.sendBeacon(urls: payload.pixels.acceptInvitationLinear)
                        }
                    }
                case .AdUserMinimize:
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.collapse)
                    }
                case .AdUserClose:
                    report { payload in
                        if payload.pixels.closeLinear.isEmpty {
                            reporter.sendBeacon(urls: payload.pixels.close)
                        } else {
                            reporter.sendBeacon(urls: payload.pixels.closeLinear)
                        }
                    }
                case .AdVolumeChange(let volume):
                    report { payload in
                        let urls = volume == 0 ? payload.pixels.mute : payload.pixels.unmute
                        reporter.sendBeacon(urls: urls)
                    }
                case .AdStarted:
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.creativeView)
                    }
                case .AdClickThru(_):
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.clickTracking)
                    }
                case .AdVideoStart:
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.start)
                        reporter.adStart(info: payload.info,
                                         videoIndex: state.playlist.currentIndex,
                                         videoViewUID: state.playbackSession.id.uuidString)
                    }
                case .AdVideoFirstQuartile:
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.firstQuartile)
                        engineFlow(stage: .Quartile1, payload: payload)
                    }
                case .AdVideoMidpoint:
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.midpoint)
                        engineFlow(stage: .Quartile2, payload: payload)
                        reporter.mrcAdViewGroupM(videoIndex: state.playlist.currentIndex,
                                                 info: payload.info,
                                                 type: adType,
                                                 autoplay: model.isAutoplayEnabled,
                                                 videoViewUID: state.playbackSession.id.uuidString)
                    }
                case .AdVideoThirdQuartile:
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.thirdQuartile)
                        engineFlow(stage: .Quartile3, payload: payload)
                    }
                case .AdVideoComplete:
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.complete)
                        engineFlow(stage: .finished, payload: payload)
                    }
                case .AdError(let error):
                    reporter.sendBeacon(urls: holder.pixels.error)
                    reporter.adEngineIssue(videoIndex: state.playlist.currentIndex,
                                           info: info,
                                           type: adType,
                                           errorMessage: error.localizedDescription,
                                           stage: .load,
                                           transactionId: state.transactionIDHolder?.transactionID,
                                           adId: holder.adID,
                                           videoViewUID: state.playerSession.id.uuidString)
                default: break
                }
            }
        case .mp4:
            /* Playback Cycle Detector */ do {
                let result = adPlaybackCycleDetector.process(streamPlaying: state.rate.adRate.stream,
                                                             isFinished: state.adTracker.isFinished)
                switch result {
                case .beginPlaying:
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.start)
                        engineFlow(stage: .started, payload: payload)
                        reporter.adStart(info: payload.info,
                                         videoIndex: state.playlist.currentIndex,
                                         videoViewUID: state.playbackSession.id.uuidString)
                    }
                    guard let duration = state.duration.ad?.seconds else { return }
                    let volume: Float = state.mute.player ? 0 : 1
                    openMeasurementVideoEvents?.start(CGFloat(duration), CGFloat(volume))
                    
                case .endPlaying:
                    guard let holder = state.adInfoHolder else { return }
                    reporter.sendBeacon(urls: holder.pixels.complete)
                    openMeasurementVideoEvents?.complete()
                    let info = VerizonVideoPartnerSDK.info(from: holder.info)
                    reporter.adEngineFlow(videoIndex: state.playlist.currentIndex,
                                          info: info,
                                          type: adType,
                                          stage: .finished,
                                          width: state.viewport.dimensions?.width,
                                          height: state.viewport.dimensions?.height,
                                          autoplay: model.isAutoplayEnabled,
                                          transactionId: state.transactionIDHolder?.transactionID,
                                          adId: holder.adID,
                                          videoViewUID: state.playbackSession.id.uuidString)
                    
                case .nothing: break
                }
            }
            
            /* Mute/Unmute Detector */ do {
                let result = muteDetector.process(isMuted: state.mute.player,
                                                  isNotFinished: !state.adTracker.isFinished)
                report { payload in
                    switch result {
                    case .mute:
                        reporter.sendBeacon(urls: payload.pixels.mute)
                        openMeasurementVideoEvents?.volumeChange(0.0)
                    case .unmute:
                        reporter.sendBeacon(urls: payload.pixels.unmute)
                        openMeasurementVideoEvents?.volumeChange(1.0)
                    case .nothing: break
                    }
                }
            }

            /* Buffering Start/End Detector */ do {
                let isAdBuffering: Bool = {
                    switch state.playbackBuffering.ad {
                    case .active:
                        return true
                    case .inactive, .unknown:
                        return false
                    }
                }()
                if let openMeasurementVideoEvents = openMeasurementVideoEvents {
                    switch bufferingDetector.process(isAdBuffering: isAdBuffering) {
                    case .bufferingStart:
                        openMeasurementVideoEvents.bufferStart()
                    case .bufferingEnd:
                        openMeasurementVideoEvents.bufferFinish()
                    case .nothing: break
                    }
                }
            }
            
            /* Open Measurement Mute/Unmute Detector */ do {
                let isOMActive: Bool = {
                    guard case .active = state.openMeasurement else { return false}
                    return true
                }()
                let result = openMeasurementMuteDetector.process(
                    isMuted: state.mute.player,
                    isNotFinished: !state.adTracker.isFinished,
                    isOMActive: isOMActive)
                switch result {
                case .mute:
                    openMeasurementVideoEvents?.volumeChange(0.0)
                case .unmute:
                    openMeasurementVideoEvents?.volumeChange(1.0)
                case .nothing: break
                }
            }
            
            /* Video Loading Detector */ do {
                let result = adVideoLoadingDetector.render(isLoaded: state.playbackStatus.ad == .ready,
                                                           sessionID: state.adVRMManager.request.id,
                                                           isPlaying: state.ad.currentAd.isPlaying)
                
                switch result {
                case .beginLoading:
                    report {
                        engineFlow(stage: .win, payload: $0)
                        engineFlow(stage: .loaded, payload: $0)
                    }
                    
                case .endLoading:
                    let adPosition: PlayerCore.OpenMeasurement.VideoEvents.AdPosition = {
                        switch state.ad.currentType {
                        case .preroll: return .preroll
                        case .midroll: return .midroll
                        }
                    }()
                    openMeasurementVideoEvents?.loaded(adPosition, model.isAutoplayEnabled)
                    openMeasurementAdEvents?.impressionOccurred()
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.impression)
                        reporter.sendBeacon(urls: payload.pixels.creativeView)
                    }
                case .nothing: break
                }
            }
            
            /* Quartile Detector */ do {
                let quartile: Int? = perform {
                    guard let duration = state.duration.ad else { return nil }
                    let progress = Progress(state.currentTime.ad.seconds / duration.seconds)
                    return progress.lastPlayedQuartile
                }
                
                let hasDuration: Bool = perform {
                    guard let duration = state.duration.ad else { return false }
                    return CMTIME_IS_INDEFINITE(duration) == false
                }
                
                let result = adQuartileDetector.process(quartile: quartile,
                                                        playing: state.rate.adRate.stream,
                                                        sessionId: state.adVRMManager.request.id,
                                                        isStatic: hasDuration)
                for metric in result {
                    switch metric.newQuartile {
                    case 1:
                        report { payload in
                            reporter.sendBeacon(urls: payload.pixels.firstQuartile)
                            engineFlow(stage: .Quartile1, payload: payload)
                        }
                        openMeasurementVideoEvents?.firstQuartile()
                    case 2:
                        report { payload in
                            reporter.sendBeacon(urls: payload.pixels.midpoint)
                            engineFlow(stage: .Quartile2, payload: payload)
                            reporter.mrcAdViewGroupM(videoIndex: state.playlist.currentIndex,
                                                     info: payload.info,
                                                     type: adType,
                                                     autoplay: model.isAutoplayEnabled,
                                                     videoViewUID: state.playbackSession.id.uuidString)
                        }
                        
                        openMeasurementVideoEvents?.midpoint()
                    case 3:
                        report { payload in
                            reporter.sendBeacon(urls: payload.pixels.thirdQuartile)
                            engineFlow(stage: .Quartile3, payload: payload)
                        }
                        
                        openMeasurementVideoEvents?.thirdQuartile()
                    default: break
                    }
                }
            }
            
            /* Ad Error Detector */ do {
                adErrorDetector.process(id: state.adVRMManager.request.id,
                                        error: perform {
                                            guard case .errored(let error) = state.playbackStatus.ad else { return nil }
                                            return error
                }).map { (issue: Detectors.AdError.Result) in
                    guard let holder = state.adInfoHolder else { return }
                    let info = VerizonVideoPartnerSDK.info(from: holder.info)
                    reporter.sendBeacon(urls: holder.pixels.error)
                    
                    reporter.adEngineIssue(videoIndex: state.playlist.currentIndex,
                                           info: info,
                                           type: adType,
                                           errorMessage: issue.error.localizedDescription,
                                           stage: .load,
                                           transactionId: state.transactionIDHolder?.transactionID,
                                           adId: holder.adID,
                                           videoViewUID: state.playerSession.id.uuidString)
                }
            }
            
            /* Ad Click Detector */ do {
                let result = adClickDetector.process(clicked: state.clickthrough.isPresentationRequested)
                if result {
                    report { payload in
                        reporter.sendBeacon(urls: payload.pixels.clickTracking)
                    }
                    openMeasurementVideoEvents?.click()
                }
            }
        case .none: break
        }
    }
}
func info(from info: PlayerCore.VRMMetaInfo) -> Ad.Metrics.Info {
    return Ad.Metrics.Info(engineType: info.engineType,
                           ruleId: info.ruleId,
                           ruleCompanyId: info.ruleCompanyId,
                           vendor: info.vendor,
                           name: info.name,
                           cpm: info.cpm)
}

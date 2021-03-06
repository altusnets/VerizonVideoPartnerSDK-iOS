//  Copyright 2018, Oath Inc.
//  Licensed under the terms of the MIT License. See LICENSE.md file in project root for terms.

import Foundation
import PlayerCore

extension OpenMeasurement {
    
    final class AdSessionController {
        
        let dispatcher: (PlayerCore.Action) -> Void
        let adViewAction: () -> UIView?
        let createOMContext: (Input) throws -> Output
        var serviceScript: String?
        
        private var adSession: OpenMeasurementAdSessionProtocol?
        private var adVerifications: [PlayerCore.Ad.VASTModel.AdVerification]?
        
        init(adViewAction: @escaping () -> UIView?,
             createOMContext: @escaping (Input) throws -> Output,
             dispatcher: @escaping (PlayerCore.Action) -> Void) {
            self.adViewAction = adViewAction
            self.dispatcher = dispatcher
            self.createOMContext = createOMContext
        }
        
        func process(with openMeasurement: PlayerCore.OpenMeasurement) {
            guard openMeasurement != .disabled else { return }
            if openMeasurement == .inactive, adSession != nil {
                return finishMeasurement()
            }
            if case .finished = openMeasurement {
                return dispatcher(PlayerCore.openMeasurementDeactivated())
            }
            
            if case .readyForLoad(let adVerifications) = openMeasurement {
                self.adVerifications = adVerifications
                return
            }
            
            guard case .loading = openMeasurement, adSession == nil else { return }
            
            guard let serviceScript = serviceScript else {
                dispatcher(PlayerCore.failedOMConfiguration(with: OpenMeasurement.Errors.scriptNotAvailable))
                return
            }
            guard let adView = adViewAction(),
                  let adVerifications = adVerifications else {
                return
            }
            
            do {
                let input = OpenMeasurement.Input(partnerBundleName: "Verizonmedia",
                                                  partnerVersion: VVPSDK.version,
                                                  jsServiceScript: serviceScript,
                                                  adVerifications: adVerifications)
                let output = try createOMContext(input)
                adSession = output.adSession
                adSession?.mainAdView = adView
                adSession?.start()
                dispatcher(PlayerCore.openMeasurementActivated(adEvents: output.adEvents,
                                                               videoEvents: output.videoEvents))
            } catch {
                dispatcher(PlayerCore.failedOMConfiguration(with: error))
            }
        }
        private func finishMeasurement() {
            adSession?.finish()
            adSession = nil
        }
    }
}

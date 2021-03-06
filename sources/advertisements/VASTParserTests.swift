//  Copyright 2018, Oath Inc.
//  Licensed under the terms of the MIT License. See LICENSE.md file in project root for terms.

import XCTest
import Foundation

@testable import VerizonVideoPartnerSDK

class VASTParserTests: XCTestCase {
    var bundle: Bundle { return Bundle(for: type(of: self)) }
    
    func getVAST(atPath path: String) -> String {
        guard let path = bundle.path(forResource: path, ofType: "xml") else {
            fatalError("Cannot extract resource")
        }
        
        guard let result = try? String(contentsOfFile: path) else {
            fatalError("Cannot build string from path: \(path)")
        }
        
        return result
    }
    
    func testParseVastWithMixedDataInMediaFile() {
        let vast = getVAST(atPath: "VAST1")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail() }
        guard case let .inline(inlineModel) = model else { return XCTFail() }
        guard let url = inlineModel.mp4MediaFiles.first?.url.absoluteString else { return XCTFail() }
        XCTAssertEqual(url,
                       "https://dev.example.com/videos/2018/video_example_1280x720.mp4")
        XCTAssertEqual(inlineModel.id, "4203085")
    }
    
    func testVASTExampleCDATA() {
        let vast = getVAST(atPath: "VASTExampleCDATA")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail() }
        guard case let .inline(inlineModel) = model else { return XCTFail() }
        
        XCTAssertEqual(inlineModel.mp4MediaFiles.first?.url.absoluteString,
                       "http://localhost:3000/adasset/1331/229/7969/lo.mp4")
    }
    
    func testParseWrapperVAST() {
        let vast = getVAST(atPath: "VASTWrapper")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail("Failed to parse VAST xml") }
        guard case let .wrapper(wrapperModel) = model else { return XCTFail() }
        let expectedUrlString = "http://myTrackingURL/adTagURL"
        XCTAssertEqual(wrapperModel.tagURL.absoluteString.removingPercentEncoding,
                       expectedUrlString)
        XCTAssertFalse(wrapperModel.adVerifications.isEmpty)
    }
    
    func testParseWrapperWithExtensionVAST() {
        let vast = getVAST(atPath: "VASTWrapperWithExtension")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail("Failed to parse VAST xml") }
        guard case let .wrapper(wrapperModel) = model else { return XCTFail() }
        XCTAssertFalse(wrapperModel.adVerifications.isEmpty)
    }
    
    func testParseVpaidVAST() {
        let vast = getVAST(atPath: "VASTVpaid")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail("Failed to parse VAST VPAID xml") }
        guard case let .inline(inlineModel) = model else { return XCTFail() }
        let expectedURLString = "http://localhost:3000/vpaid/6/video.js"
        XCTAssertEqual(inlineModel.vpaidMediaFiles.first?.url.absoluteString, expectedURLString)
    }
    
    func testParseAdVerification() {
        let vast = getVAST(atPath: "VAST1")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail() }
        guard case .inline(let inlineModel) = model else { return XCTFail() }
        
        XCTAssertEqual(inlineModel.adVerifications.count, 1)
        guard let adVerification = inlineModel.adVerifications.first else { return XCTFail("Missing AdVerification") }
        
        XCTAssertEqual(adVerification.vendorKey, "TestAppVendor")
        XCTAssertEqual(adVerification.javaScriptResource.absoluteString, "https://verificationcompany1.com/verification_script1.js")
        XCTAssertEqual(adVerification.verificationParameters?.absoluteString, "http://localhost:3000/0/beacons")
        XCTAssertEqual(adVerification.verificationNotExecuted?.absoluteString, "http://localhost:3000/0/beacons/vast/verification-not-executed.gif")
    }
    
    func testParseAdVerificatiosWhereOnenWithoutVendorAndParameters() {
        let vast = getVAST(atPath: "VASTExampleCDATA")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail() }
        guard case .inline(let inlineModel) = model else { return XCTFail() }
        
        XCTAssertEqual(inlineModel.adVerifications.count, 2)
    }
    
    func testParseAdVerificationWithoutResource() {
        let vast = getVAST(atPath: "VASTVpaid")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail() }
        guard case .inline(let inlineModel) = model else { return XCTFail() }
        
        XCTAssertNil(inlineModel.adVerifications.first)
    }
    
    func testParseAdVerificationInExtension() {
        let vast = getVAST(atPath: "VASTVerificationInExtension")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail() }
        guard case .inline(let inlineModel) = model else { return XCTFail() }
        
        XCTAssertNotNil(inlineModel.adVerifications.first)
    }
    
    func testParsePixelsFromVAST() {
        let vast = getVAST(atPath: "VASTExampleCDATA")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail("Failed to parse VAST VPAID xml") }
        guard case let .inline(inlineModel) = model else { return XCTFail() }
        let url = "http://localhost:3000/6/beacons/vast/"
        XCTAssertEqual(inlineModel.pixels.impression.first?.absoluteString, url + "impression.gif")
        XCTAssertEqual(inlineModel.pixels.error.first?.absoluteString, url + "error.gif")
        XCTAssertEqual(inlineModel.pixels.clickTracking.first?.absoluteString, url + "click.gif")
        XCTAssertEqual(inlineModel.pixels.firstQuartile.first?.absoluteString, url + "firstQuartile.gif")
        XCTAssertEqual(inlineModel.pixels.midpoint.first?.absoluteString, url + "midpoint.gif")
        XCTAssertEqual(inlineModel.pixels.thirdQuartile.first?.absoluteString, url + "thirdQuartile.gif")
        XCTAssertEqual(inlineModel.pixels.complete.first?.absoluteString, url + "complete.gif")
        XCTAssertEqual(inlineModel.pixels.pause.first?.absoluteString, url + "pause.gif")
        XCTAssertEqual(inlineModel.pixels.resume.first?.absoluteString, url + "resume.gif")
        XCTAssertEqual(inlineModel.pixels.skip.first?.absoluteString, url + "skip.gif")
        XCTAssertEqual(inlineModel.pixels.mute.first?.absoluteString, url + "mute.gif")
        XCTAssertEqual(inlineModel.pixels.unmute.first?.absoluteString, url + "unmute.gif")
        XCTAssertEqual(inlineModel.pixels.acceptInvitation.first?.absoluteString, url + "acceptInvitation.gif")
        XCTAssertEqual(inlineModel.pixels.close.first?.absoluteString, url + "close.gif")
        XCTAssertEqual(inlineModel.pixels.collapse.first?.absoluteString, url + "collapse.gif")
        XCTAssertEqual(inlineModel.adProgress.first?.url.absoluteString, url + "progress.gif")
    }
    
    func testParseOffsetInTime() {
        let vast = getVAST(atPath: "VAST1")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail("Failed to parse VAST VPAID xml") }
        guard case let .inline(inlineModel) = model else { return XCTFail() }
        XCTAssertEqual(inlineModel.skipOffset, .time(3663))
        XCTAssertEqual(inlineModel.adProgress.first?.offset, .time(60))
    }
    
    func testParseOffsetInPersentage() {
        let vast = getVAST(atPath: "VASTExampleCDATA")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail("Failed to parse VAST VPAID xml") }
        guard case let .inline(inlineModel) = model else { return XCTFail() }
        XCTAssertEqual(inlineModel.skipOffset, .percentage(32))
        XCTAssertEqual(inlineModel.adProgress.first?.offset, .percentage(10))
    }
    
    func testParseNotValidSkipOffsetInTime() {
        let vast = getVAST(atPath: "VASTVerificationInExtension")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail("Failed to parse VAST VPAID xml") }
        guard case let .inline(inlineModel) = model else { return XCTFail() }
        XCTAssertEqual(inlineModel.skipOffset, nil)
    }
    
    func testParseMultipleCreatives() {
        let vast = getVAST(atPath: "VASTMultipleCreatives")
        guard let model = VASTParser.parseFrom(string: vast) else { return XCTFail("Failed to parse VAST VPAID xml") }
        guard case let .inline(inlineModel) = model else { return XCTFail() }
        XCTAssertEqual(inlineModel.mp4MediaFiles.count, 3)
        XCTAssertEqual(inlineModel.pixels.firstQuartile.count, 1)
        XCTAssertEqual(inlineModel.skipOffset, .percentage(32))
    }

}

//
//  MockAnnouncement.swift
//  BlockchainTests
//
//  Created by Daniel Huri on 29/07/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import RxSwift
import XCTest

@testable import PlatformKit
@testable import PlatformUIKit
@testable import ToolKit

class MockAnalyticsService: AnalyticsServiceAPI {
    func trackEvent(title: String, parameters: [String: Any]?) { }
}

struct MockOneTimeAnnouncement: OneTimeAnnouncement {
    
    var viewModel: AnnouncementCardViewModel {
        fatalError("\(#function) was not implemented")
    }
    
    var shouldShow: Bool {
        !isDismissed
    }
    
    let dismiss: CardAnnouncementAction
    let recorder: AnnouncementRecorder
    let type: AnnouncementType
    let analyticsRecorder: AnalyticsEventRecording
    
    init(type: AnnouncementType,
         cacheSuite: CacheSuite,
         analyticsRecorder: AnalyticsEventRecording = AnalyticsEventRecorder(analyticsService: MockAnalyticsService()),
         dismiss: @escaping CardAnnouncementAction) {
        self.type = type
        recorder = AnnouncementRecorder(cache: cacheSuite, errorRecorder: MockErrorRecorder())
        self.analyticsRecorder = analyticsRecorder
        self.dismiss = dismiss
    }
}

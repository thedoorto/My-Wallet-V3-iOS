//
//  AnnouncementsMetadata.swift
//  PlatformUIKit
//
//  Created by Daniel Huri on 02/09/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformKit

public struct AnnouncementsMetadata: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case interval
        case order
    }
    
    public let order: [AnnouncementType]
    public let interval: TimeInterval
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let order = try container.decode([String].self, forKey: .order)
        self.order = order.compactMap { AnnouncementType(rawValue: $0) }
        let days = try container.decode(Int.self, forKey: .interval)
        interval = TimeInterval(days) * .day
    }
}

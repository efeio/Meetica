//
//  Option.swift
//  LivePolls
//
//  Created by Efe Koç on 09/07/23.
//

import Foundation

struct Option: Codable, Identifiable, Hashable {
    var id = UUID().uuidString
    var count: Int
    var name: String
}

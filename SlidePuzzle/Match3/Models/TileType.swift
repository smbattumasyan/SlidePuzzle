//
//  TileType.swift
//  SlidePuzzle
//
//  Match-3 dragon egg tile kinds.
//

import Foundation

enum TileType: Int, CaseIterable {
    case lava
    case purple
    case crystal
    case peacock
    case pearl
    case navy

    var assetName: String {
        switch self {
        case .lava:    return "egg_lava"
        case .purple:  return "egg_purple"
        case .crystal: return "egg_crystal"
        case .peacock: return "egg_peacock"
        case .pearl:   return "egg_pearl"
        case .navy:    return "egg_navy"
        }
    }

    static func random(excluding excluded: Set<TileType> = []) -> TileType {
        let candidates = allCases.filter { !excluded.contains($0) }
        return candidates.randomElement() ?? .lava
    }
}

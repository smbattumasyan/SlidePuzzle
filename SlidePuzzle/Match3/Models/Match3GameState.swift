//
//  Match3GameState.swift
//  SlidePuzzle
//
//  Observable game state shared between the SwiftUI HUD and the SpriteKit scene.
//

import Foundation
import Observation

@Observable
final class Match3GameState {
    var score: Int = 0
    /// True while the scene is animating a move; input is locked.
    var isResolving: Bool = false

    func reset() {
        score = 0
        isResolving = false
    }
}

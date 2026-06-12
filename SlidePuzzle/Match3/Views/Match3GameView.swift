//
//  Match3GameView.swift
//  SlidePuzzle
//
//  SwiftUI host for the Match-3 game: SpriteKit board + score HUD.
//

import SwiftUI
import SpriteKit

struct Match3GameView: View {
    // Created once; never rebuilt on re-render (would reset the game).
    @State private var gameState: Match3GameState
    @State private var scene: Match3Scene

    init() {
        let state = Match3GameState()
        let board = Match3Board(columns: 7, rows: 7)
        _gameState = State(initialValue: state)
        _scene = State(initialValue: Match3Scene(gameState: state, board: board))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Score")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("\(gameState.score)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.snappy, value: gameState.score)
                }
                Spacer()
                Button {
                    scene.restart()
                } label: {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
                .disabled(gameState.isResolving)
            }
            .padding(.horizontal)

            SpriteView(scene: scene)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Match 3")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        Match3GameView()
    }
}

//
//  MainMenuView.swift
//  SlidePuzzle
//
//  App entry menu: choose between the classic slide puzzle (Obj-C/UIKit)
//  and the new Match-3 game (SwiftUI/SpriteKit).
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image("egg_peacock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 28))

                Text("Puzzle Box")
                    .font(.largeTitle.bold())

                Spacer()

                NavigationLink {
                    Match3GameView()
                } label: {
                    menuLabel("Match 3", systemImage: "circle.hexagongrid.fill")
                }

                NavigationLink {
                    SlidePuzzleView()
                        .ignoresSafeArea(edges: .bottom)
                        .navigationTitle("Slide Puzzle")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    menuLabel("Slide Puzzle", systemImage: "square.grid.4x3.fill")
                }

                Spacer()
            }
            .padding(32)
        }
    }

    private func menuLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.title2.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentColor.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    MainMenuView()
}

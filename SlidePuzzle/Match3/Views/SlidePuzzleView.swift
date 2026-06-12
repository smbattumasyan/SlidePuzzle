//
//  SlidePuzzleView.swift
//  SlidePuzzle
//
//  SwiftUI wrapper around the original Objective-C SPViewController,
//  instantiated from Main.storyboard.
//

import SwiftUI

struct SlidePuzzleView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "SPViewController")
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

//
//  MenuFactory.swift
//  SlidePuzzle
//
//  Obj-C-visible factory so AppDelegate.m can install the SwiftUI root.
//

import SwiftUI

@objc(SPMenuFactory)
final class MenuFactory: NSObject {
    @objc static func makeRootViewController() -> UIViewController {
        UIHostingController(rootView: MainMenuView())
    }
}

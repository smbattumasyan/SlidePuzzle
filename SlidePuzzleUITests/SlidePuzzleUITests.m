//
//  SlidePuzzleUITests.m
//  SlidePuzzleUITests
//
//  Created by Smbat Tumasyan on 3/14/16.
//  Copyright © 2016 EGS. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface SlidePuzzleUITests : XCTestCase

@end

@implementation SlidePuzzleUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

/// Navigates: menu -> Match 3, verifies the board screen appears,
/// then tries adjacent swaps until the score changes (a match resolved).
- (void)testMatch3NavigationAndFirstMatch {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *match3Button = app.buttons[@"Match 3"];
    XCTAssertTrue([match3Button waitForExistenceWithTimeout:5]);
    [match3Button tap];

    XCUIElement *scoreLabel = app.staticTexts[@"Score"];
    XCTAssertTrue([scoreLabel waitForExistenceWithTimeout:5]);

    // Let the board build, and give the host a moment to take a screenshot.
    [NSThread sleepForTimeInterval:4.0];

    // Board geometry (points): SpriteView is square, inset 16pt each side,
    // sitting below the HUD. Measured from the app frame.
    CGRect frame = app.frame;
    CGFloat boardSide = frame.size.width - 32.0;
    CGFloat boardLeft = 16.0;
    // nav bar + HUD: score block ~ starts after navigation bar; SpriteView top
    // measured at ~196pt on iPhone 17 Pro. Scene letterboxes a 760x760 design
    // into the square view; grid spans 700/760 of the side, centered.
    CGFloat boardTop = 196.0;
    CGFloat gridSide = boardSide * (700.0 / 760.0);
    CGFloat gridLeft = boardLeft + (boardSide - gridSide) / 2.0;
    CGFloat gridTop = boardTop + (boardSide - gridSide) / 2.0;
    CGFloat cell = gridSide / 7.0;

    XCUIElement *scoreValue = app.staticTexts[@"0"];
    XCTAssertTrue(scoreValue.exists);

    BOOL scored = NO;
    for (int row = 0; row < 7 && !scored; row++) {
        for (int col = 0; col < 6 && !scored; col++) {
            CGFloat x1 = gridLeft + (col + 0.5) * cell;
            CGFloat y  = gridTop + (row + 0.5) * cell;
            CGFloat x2 = gridLeft + (col + 1.5) * cell;

            XCUICoordinate *origin = [app coordinateWithNormalizedOffset:CGVectorMake(0, 0)];
            [[origin coordinateWithOffset:CGVectorMake(x1, y)] tap];
            [[origin coordinateWithOffset:CGVectorMake(x2, y)] tap];
            [NSThread sleepForTimeInterval:1.2]; // allow cascade animation

            if (!app.staticTexts[@"0"].exists) {
                scored = YES;
            }
        }
    }

    XCTAssertTrue(scored, @"No swap produced a match; score never changed");

    // Hold the final board on screen briefly.
    [NSThread sleepForTimeInterval:2.0];
}

/// Navigates: menu -> Slide Puzzle (legacy Obj-C SPViewController via storyboard),
/// verifies the Choose Image button is present, and returns to the menu.
- (void)testSlidePuzzleNavigation {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *slidePuzzleButton = app.buttons[@"Slide Puzzle"];
    XCTAssertTrue([slidePuzzleButton waitForExistenceWithTimeout:5]);
    [slidePuzzleButton tap];

    XCUIElement *chooseImageButton = app.buttons[@"Choose Image"];
    XCTAssertTrue([chooseImageButton waitForExistenceWithTimeout:5]);

    [app.navigationBars.buttons.firstMatch tap]; // back
    XCTAssertTrue([app.buttons[@"Match 3"] waitForExistenceWithTimeout:5]);
}

@end

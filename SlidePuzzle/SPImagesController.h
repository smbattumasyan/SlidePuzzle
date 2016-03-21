//
//  SPImagesController.h
//  SlidePuzzle
//
//  Created by Smbat Tumasyan on 3/21/16.
//  Copyright © 2016 EGS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPBoard.h"

@interface SPImagesController : NSObject
@property(strong, nonatomic) SPBoard *spboard;

- (void)moveImages:(UITouch *)touch;
- (BOOL)checkEquality;
+ (instancetype)createInstance;

@end

//
//  SPBoard.h
//  SlidePuzzle
//
//  Created by Smbat Tumasyan on 3/21/16.
//  Copyright © 2016 EGS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPBoard : NSObject

@property (strong, nonatomic) NSMutableArray<UIImageView       *> *cropedImages;
@property (assign, nonatomic) CGPoint        freePlace;
@property (strong, nonatomic) NSMutableArray<NSValue        *> *points;
@property (strong, nonatomic) UIView      *boardView;

- (void)setCropImages:(UIImage *)image;
- (CGPoint)coordinateFromPoint:(CGPoint)point;
+ (instancetype)createInstance;

@end

//
//  SPImagesController.m
//  SlidePuzzle
//
//  Created by Smbat Tumasyan on 3/21/16.
//  Copyright © 2016 EGS. All rights reserved.
//

#import "SPImagesController.h"


@interface SPImagesController ()


@end

@implementation SPImagesController

+ (instancetype)createInstance
{
    SPImagesController *spimageController = [[SPImagesController alloc] init];
    return spimageController;
}

- (void)moveImages:(UITouch *)touch
{
    if ([touch view] == self.spboard.boardView) {
        CGPoint touchLocation = [touch locationInView:self.spboard.boardView];
        CGRect checkRect      = CGRectMake(touchLocation.x,touchLocation.y, 1.0, 1.0);
        for (UIImageView *img in self.spboard.cropedImages) {
            if  (CGRectIntersectsRect(img.frame, checkRect))
            {
                if ([self.spboard coordinateFromPoint:checkRect.origin].x+1 == self.spboard.freePlace.x && [self.spboard coordinateFromPoint:checkRect.origin].y == self.spboard.freePlace.y) {
                    img.frame              = CGRectMake(img.frame.origin.x+img.frame.size.width, img.frame.origin.y, img.frame.size.width, img.frame.size.height);
                    self.spboard.freePlace = [self.spboard coordinateFromPoint:checkRect.origin];
                } else if ([self.spboard coordinateFromPoint:checkRect.origin].y+1 == self.spboard.freePlace.y && [self.spboard coordinateFromPoint:checkRect.origin].x == self.spboard.freePlace.x) {
                    img.frame              = CGRectMake(img.frame.origin.x, img.frame.origin.y+img.frame.size.width, img.frame.size.width, img.frame.size.height);
                    self.spboard.freePlace = [self.spboard coordinateFromPoint:checkRect.origin];
                } else if ([self.spboard coordinateFromPoint:checkRect.origin].x-1== self.spboard.freePlace.x && [self.spboard coordinateFromPoint:checkRect.origin].y == self.spboard.freePlace.y) {
                    img.frame              = CGRectMake(img.frame.origin.x-img.frame.size.width, img.frame.origin.y, img.frame.size.width, img.frame.size.height);
                    self.spboard.freePlace = [self.spboard coordinateFromPoint:checkRect.origin];
                } else if ([self.spboard coordinateFromPoint:checkRect.origin].y-1== self.spboard.freePlace.y && [self.spboard coordinateFromPoint:checkRect.origin].x == self.spboard.freePlace.x) {
                    img.frame              = CGRectMake(img.frame.origin.x, img.frame.origin.y-img.frame.size.width, img.frame.size.width, img.frame.size.height);
                    self.spboard.freePlace = [self.spboard coordinateFromPoint:checkRect.origin];
                }
                break;
            }
        }
    }
}

- (BOOL)checkEquality
{
    for (int i = 0; i < self.spboard.points.count; i++) {
        if ((int)self.spboard.points[i].CGPointValue.x != (int)self.spboard.cropedImages[i].frame.origin.x || (int)self.spboard.points[i].CGPointValue.y != (int)self.spboard.cropedImages[i].frame.origin.y) {
            return NO;
        }
    }
    return YES;
}

@end

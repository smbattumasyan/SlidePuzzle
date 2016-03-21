//
//  SPBoard.m
//  SlidePuzzle
//
//  Created by Smbat Tumasyan on 3/21/16.
//  Copyright © 2016 EGS. All rights reserved.
//

#import "SPBoard.h"

@interface SPBoard ()

@property (assign, nonatomic) CGFloat     cropedImageWeight;
@property (assign, nonatomic) CGFloat     cropedImageHeight;
@property (assign, nonatomic) NSInteger   size;

@end

@implementation SPBoard

+ (instancetype)createInstance
{
    SPBoard *spboard = [[SPBoard alloc] init];
    return spboard;
}


- (CGPoint)coordinateFromPoint:(CGPoint)point
{
    return CGPointMake((int)(point.x / self.cropedImageWeight)+1, (int)(point.y / self.cropedImageHeight)+1);
}

- (void)setCropImages:(UIImage *)image {
    
    self.cropedImages = [[NSMutableArray alloc] init];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.boardView.frame.size.width, self.boardView.frame.size.height)];
    self.size = 4;
    
    self.cropedImageWeight = imageView.frame.size.width/self.size;
    self.cropedImageHeight = imageView.frame.size.height/self.size;
    for (int i = 0; i < self.size;i++ ) {
        for (int j = 0; j < self.size; j++) {
            imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.cropedImageWeight*j, self.cropedImageHeight*i, self.cropedImageWeight-1, self.cropedImageHeight-1)];
            imageView.image = [self getSubImageFrom:image WithRect:CGRectMake(self.cropedImageWeight*j, self.cropedImageHeight*i, self.cropedImageWeight, self.cropedImageHeight)];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.cropedImageWeight/2-5, self.cropedImageHeight/2-5, 20, 15)];
            static int c = 1;
            label.text = [NSString stringWithFormat:@"%d",c++ ];
            [imageView addSubview:label];
            [self.cropedImages addObject:imageView];
        }
    }
    [self.cropedImages removeLastObject];
    [self addImagesInBoardView];
}

- (UIImage *)getSubImageFrom: (UIImage*) img WithRect: (CGRect) rect {
    
    img = [self imageWithImage:img scaledToSize:CGSizeMake(self.boardView.frame.size.width, self.boardView.frame.size.height)];
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // translated rectangle for drawing sub image
    CGRect drawRect = CGRectMake(-rect.origin.x, -rect.origin.y, img.size.width, img.size.height);
    
    // clip to the bounds of the image context
    // not strictly necessary as it will get clipped anyway?
    CGContextClipToRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height));
    
    // draw image
    [img drawInRect:drawRect];
    
    // grab image
    UIImage* subImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return subImage;
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)addImagesInBoardView
{
    self.points = [[NSMutableArray alloc] init];
    for (UIImageView *img in self.cropedImages) {
        [self.boardView addSubview:img];
        [self.points addObject:[NSValue valueWithCGPoint:img.frame.origin]];
    }
    
    self.freePlace = CGPointMake(self.size, self.size);
}

@end

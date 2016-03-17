//
//  SPViewController.m
//  SlidePuzzle
//
//  Created by Smbat Tumasyan on 3/14/16.
//  Copyright © 2016 EGS. All rights reserved.
//

#import "SPViewController.h"

@interface SPViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView   *boardView;
@property (weak, nonatomic) IBOutlet UIButton *openButton;

@property (strong, nonatomic) NSMutableArray<NSValue *>        *points;
@property (strong, nonatomic) NSMutableArray<UIImageView    *> *cropedImages;
@property (assign, nonatomic) CGFloat        cropedImageWeight;
@property (assign, nonatomic) CGFloat        cropedImageHeight;
@property (assign, nonatomic) CGPoint        freePlace;
@property (assign, nonatomic) NSMutableArray *imagesPoints;
@property (assign, nonatomic) NSInteger      size;
@property (strong, nonatomic) UIImage        *imageFromGallery;

@end

@implementation SPViewController

//------------------------------------------------------------------------------------------
#pragma mark - Life Cyrcle
//------------------------------------------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.boardView.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//    UIImageView *imageView;
    UITouch *touch = [[event allTouches] anyObject];
    if ([touch view] == self.boardView) {
        CGPoint touchLocation = [touch locationInView:self.boardView];
        CGRect checkRect = CGRectMake(touchLocation.x,touchLocation.y, 1.0, 1.0);
        for (UIImageView *img in self.cropedImages) {
            if  (CGRectIntersectsRect(img.frame, checkRect))
            {
                if ([self coordinateFromPoint:checkRect.origin].x+1 == self.freePlace.x && [self coordinateFromPoint:checkRect.origin].y == self.freePlace.y) {
                    img.frame = CGRectMake(img.frame.origin.x+img.frame.size.width, img.frame.origin.y, img.frame.size.width, img.frame.size.height);
                    self.freePlace = [self coordinateFromPoint:checkRect.origin];
                } else if ([self coordinateFromPoint:checkRect.origin].y+1 == self.freePlace.y && [self coordinateFromPoint:checkRect.origin].x == self.freePlace.x) {
                    img.frame = CGRectMake(img.frame.origin.x, img.frame.origin.y+img.frame.size.width, img.frame.size.width, img.frame.size.height);
                    self.freePlace = [self coordinateFromPoint:checkRect.origin];
                } else if ([self coordinateFromPoint:checkRect.origin].x-1== self.freePlace.x && [self coordinateFromPoint:checkRect.origin].y == self.freePlace.y) {
                    img.frame = CGRectMake(img.frame.origin.x-img.frame.size.width, img.frame.origin.y, img.frame.size.width, img.frame.size.height);
                    self.freePlace = [self coordinateFromPoint:checkRect.origin];
                } else if ([self coordinateFromPoint:checkRect.origin].y-1== self.freePlace.y && [self coordinateFromPoint:checkRect.origin].x == self.freePlace.x) {
                    img.frame = CGRectMake(img.frame.origin.x, img.frame.origin.y-img.frame.size.width, img.frame.size.width, img.frame.size.height);
                    self.freePlace = [self coordinateFromPoint:checkRect.origin];
                }
                break;
            }
        }
        NSLog(@"%d",[self chekEquality]);
        if ([self chekEquality])
        {
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Congratulations" message:@"You got it" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:ok];
            
            [self presentViewController:alertController animated:YES completion:nil];
            
        }
        
    }
}

//------------------------------------------------------------------------------------------
#pragma mark - Private Methods
//------------------------------------------------------------------------------------------

- (CGPoint)coordinateFromPoint:(CGPoint)point
{
    return CGPointMake((int)(point.x / self.cropedImageWeight)+1, (int)(point.y / self.cropedImageHeight)+1);
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
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

- (IBAction)openButtonAction:(id)sender {
    [self setupImagePicker];
}

- (void)setupImagePicker
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.cropedImages = [[NSMutableArray alloc] init];
    //You can retrieve the actual UIImage
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    //Or you can get the image url from AssetsLibrary
//    NSURL *path = [info valueForKey:UIImagePickerControllerReferenceURL];
   
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self setCropImages:image];
    [self addImagesInBoardView];
}

- (void)setCropImages:(UIImage *)image {
    
    self.cropedImages = [[NSMutableArray alloc] init];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.boardView.frame.size.width, self.boardView.frame.size.height)];
    self.size = 5;
    
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
    self.openButton.hidden = YES;
    self.boardView.hidden = NO;
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

- (BOOL)chekEquality
{
    for (int i = 0; i < self.points.count; i++) {
//        NSLog(@"%f   ==   %f   &&   %f   ==   %f",self.points[i].CGPointValue.x,self.cropedImages[i].frame.origin.x,self.points[i].CGPointValue.y,self.cropedImages[i].frame.origin.y);
        if ((int)self.points[i].CGPointValue.x != (int)self.cropedImages[i].frame.origin.x || (int)self.points[i].CGPointValue.y != (int)self.cropedImages[i].frame.origin.y) {
//            NSLog(@"notequal%d",i);
//            NSLog(@"%f   ==   %f   &&   %f   ==   %f",self.points[i].CGPointValue.x,self.cropedImages[i].frame.origin.x,self.points[i].CGPointValue.y,self.cropedImages[i].frame.origin.y);
            return NO;
        }
    }
    
//    NSLog(@"yes");
    return YES;
}

@end

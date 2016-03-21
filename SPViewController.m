//
//  SPViewController.m
//  SlidePuzzle
//
//  Created by Smbat Tumasyan on 3/14/16.
//  Copyright © 2016 EGS. All rights reserved.
//

#import "SPViewController.h"
#import "SPBoard.h"
#import "SPImagesController.h"

@interface SPViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic  ) IBOutlet UIView             *boardView;
@property (weak, nonatomic  ) IBOutlet UIButton           *openButton;
@property (strong, nonatomic) SPBoard            *spboard;
@property (strong, nonatomic) SPImagesController *spimageController;

@end

@implementation SPViewController

//------------------------------------------------------------------------------------------
#pragma mark - Life Cyrcle
//------------------------------------------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.boardView.hidden          = YES;
    self.spboard                   = [SPBoard createInstance];
    self.spboard.boardView         = self.boardView;
    self.spimageController         = [SPImagesController createInstance];
    self.spimageController.spboard = self.spboard;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



//------------------------------------------------------------------------------------------
#pragma mark - IBOutlets Action
//------------------------------------------------------------------------------------------

- (IBAction)openButtonAction:(id)sender {
    [self setupImagePicker];
}

//------------------------------------------------------------------------------------------
#pragma mark - Private Methods
//------------------------------------------------------------------------------------------

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    [self.spimageController moveImages:touch];
    NSLog(@"%d",[self.spimageController checkEquality]);
    [self alertView:[self.spimageController checkEquality]];
}

- (void)alertView:(BOOL)isEqual
{
    if (isEqual)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Congratulations" message:@"You got it" preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* ok                  = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)setupImagePicker
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType               = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate                 = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //You can retrieve the actual UIImage
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];   
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self.spboard setCropImages:image];
    self.boardView.hidden = NO;
}


@end

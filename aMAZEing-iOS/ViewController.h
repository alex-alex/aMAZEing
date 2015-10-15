//
//  ViewController.h
//  aMAZEing-iOS
//
//  Created by Alex Studnicka on 25/02/14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

@import AVFoundation;
@import ImageIO;
@import CoreVideo;

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
	
	__weak IBOutlet UIView *_cameraView;
	__weak IBOutlet UIImageView *_imageView;
	
	__weak IBOutlet UIButton *_button;
	__weak IBOutlet UIActivityIndicatorView *_activityIndicator;
	
}

- (IBAction)buttonTapped;

@end

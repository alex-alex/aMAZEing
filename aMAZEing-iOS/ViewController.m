//
//  ViewController.m
//  aMAZEing-iOS
//
//  Created by Alex Studnicka on 25/02/14.
//  Copyright (c) 2014 Alex Studnička. All rights reserved.
//

#import "ViewController.h"
#import "CGImageInspection.h"
#import "Pathfinding.h"

@implementation ViewController {
	
	// Camera session
	AVCaptureSession *_captureSession;
	AVCaptureStillImageOutput *_stillImageOutput;
	AVCaptureVideoDataOutput *_dataOutput;
	
	// Flag to prevent infinite loop
	BOOL processing;
	BOOL result;

	// Orignial maze image
	UIImage *_originalImage;
	
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_button.layer.cornerRadius = 40;
	_button.layer.borderWidth = 2;
	_button.layer.borderColor = self.view.tintColor.CGColor;

	_captureSession = [AVCaptureSession new];
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	NSError *error = nil;
	
	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	if (input) {
		[_captureSession addInput:input];
	} else {
		NSLog(@"Error: %@", error);
	}
	
	_stillImageOutput = [AVCaptureStillImageOutput new];
	_stillImageOutput.outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
	[_captureSession addOutput:_stillImageOutput];
	
	_dataOutput = [AVCaptureVideoDataOutput new];
	_dataOutput.alwaysDiscardsLateVideoFrames = YES;
	_dataOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
	[_captureSession addOutput:_dataOutput];
	
	AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    previewLayer.frame = self.view.layer.bounds;
    [_cameraView.layer addSublayer:previewLayer];
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[_captureSession startRunning];
	_imageView.hidden = YES;
}

#pragma mark - Utilities

- (AVCaptureConnection *)videoConnection {
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in _stillImageOutput.connections) {
		for (AVCaptureInputPort *port in connection.inputPorts) {
			if ([port.mediaType isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) break;
	}
	return videoConnection;
}

- (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
	UIGraphicsBeginImageContext( newSize );
	[image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

#pragma mark - Maze solving

- (void)solveMaze {
	
	processing = YES;
	[_captureSession stopRunning];
	
	// Get copy of user's image
	UIImage *image = [self imageWithImage:_originalImage scaledToSize:CGSizeMake(_originalImage.size.width*0.33, _originalImage.size.height*0.33)];
	
	// Process image in thread, so UI won't be blocked
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		// -------------------- Proccesing image to array grid --------------------
		
		// Init CGImageInspection with input image
		CGImageRef cgImage = image.CGImage;
		CGImageInspection *imageInspector = [CGImageInspection imageInspectionWithCGImage:cgImage];
		
		// Get Image Dimensions
		CGSize size = CGSizeMake(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));
		
		// Alloc pixel grid
		NSMutableArray *grid = [NSMutableArray arrayWithCapacity:size.height];
		
		// Coordinates of start and goal
		NSArray *start;
		NSArray *goal;
		
		NSMutableArray *starts = [NSMutableArray array];
		NSMutableArray *goals = [NSMutableArray array];
		
		// Process image pixels to grid array
		int realrow = 0;
		for (int row = 0; row < size.height; row++) {
			NSMutableArray *rowArray = [NSMutableArray arrayWithCapacity:size.width];
			for (int col = 0; col < size.width; col++) {
				
				CGFloat r, g, b, a;
				[imageInspector colorAt:CGPointMake(col, row) red:&r green:&g blue:&b alpha:&a];
				
				if (r > 0.75 && g < 0.33 && b < 0.33) {
					[starts addObject:@{@"row": @(row), @"col": @(col)}];
				} else if (r < 0.4 && g > 0.6 && b < 0.4) {
					[goals addObject:@{@"row": @(row), @"col": @(col)}];
				}
				
				if (r < 0.6 && g < 0.6 && b < 0.6) {
					// When dark color, set obstacle
					[rowArray addObject:@YES];
				} else {
					// Otherwise, free space
					[rowArray addObject:@NO];
				}
				
			}
			[grid addObject:rowArray];
			realrow++;
		}
		
		if (starts.count > 0 && goals.count > 0) {
			start = @[[starts valueForKeyPath:@"@avg.row"], [starts valueForKeyPath:@"@avg.col"]];
			goal = @[[goals valueForKeyPath:@"@avg.row"], [goals valueForKeyPath:@"@avg.col"]];
		}
		
		// Draw maze
		UIImage *img = [self drawMaze:grid size:size init:start goal:goal path:nil];
		
		// Perform UI operations on main thread
		dispatch_sync(dispatch_get_main_queue(), ^{
			
			// Set output image
			_imageView.hidden = NO;
			_imageView.image = img;
			
		});
		
		// ----------------------------- Compute path -----------------------------
		
		NSArray *path;
		
		// When start or goal is not found
		if (!start || !goal) {
			
			// Perform UI operations on main thread
			dispatch_sync(dispatch_get_main_queue(), ^{

				UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Start and/or goal not found" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				
			});
			
		} else {
			
			Pathfinding *planning = [[Pathfinding alloc] initWithGrid:grid init:start goal:goal];
			[planning astar];
			
			path = planning.path;
			
		}
		
		// Convert array of coordinates to NSBezierPath for drawing
		
		UIBezierPath *bezierPath = [UIBezierPath bezierPath];
		for (int i = 0; i < path.count; i++) {
			CGPoint point = CGPointMake(0+([path[i][1] floatValue]), ([path[i][0] floatValue]));
			if (i == 0) {
				[bezierPath moveToPoint:point];
			} else {
				[bezierPath addLineToPoint:point];
			}
		}
		
		// Draw maze with solved path
		img = [self drawMaze:grid size:size init:start goal:goal path:bezierPath];
		
		// Perform UI operations on main thread
		dispatch_sync(dispatch_get_main_queue(), ^{
			
			// Set output image
			[_imageView setImage:img];
			
			// Hide progress indicator
			[_activityIndicator stopAnimating];
			[_button setImage:[UIImage imageNamed:@"Camera"] forState:UIControlStateNormal];
			_button.enabled = YES;
			
			// Set flags
			processing = NO;
			result = YES;
			
		});
		
	});
	
}

#pragma mark - Maze drawing

- (UIImage *)drawMaze:(NSArray *)grid size:(CGSize)size init:(NSArray *)init goal:(NSArray *)goal path:(UIBezierPath *)path {
	
	UIGraphicsBeginImageContextWithOptions(size, YES, UIScreen.mainScreen.scale);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Draw maze
	
	CGContextSetFillColorWithColor(context, UIColor.whiteColor.CGColor);
	CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
	
	[_originalImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
	
	// Draw path
	
	if (path) {
		path.lineWidth = 2;
		[[UIColor redColor] set];
		[path stroke];
	}
	
	// Draw start and goal
	
	CGFloat pointSize = 5;
	[[UIColor redColor] set];
	[[UIBezierPath bezierPathWithOvalInRect:CGRectMake([init[1] intValue]-(pointSize/2), [init[0] intValue]-(pointSize/2), pointSize, pointSize)] fill];
	[[UIColor greenColor] set];
	[[UIBezierPath bezierPathWithOvalInRect:CGRectMake([goal[1] intValue]-(pointSize/2), [goal[0] intValue]-(pointSize/2), pointSize, pointSize)] fill];

	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return img;
	
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	
	[_dataOutput setSampleBufferDelegate:nil queue:NULL];
	
	CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
	CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
	UIImage *newImage = [UIImage imageWithCIImage:image scale:1.0 orientation:UIImageOrientationRight];
	_originalImage = newImage;
	[self solveMaze];
	
}

#pragma mark - Actions

- (IBAction)refresh {
	result = NO;
	[_captureSession startRunning];
	_imageView.hidden = YES;
}

- (IBAction)buttonTapped {
	
	if (processing) {
		return;
	}
	
	if (result) {
		[self refresh];
	} else {
		[_activityIndicator startAnimating];
		[_button setImage:nil forState:UIControlStateNormal];
		_button.enabled = NO;
		
		[_dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
	}
	
}

@end

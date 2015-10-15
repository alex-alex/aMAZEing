//
//  AppDelegate.m
//  aMAZEing
//
//  Created by Alex Studnička on 24.09.13.
//  Copyright (c) 2013 Alex Studnička. All rights reserved.
//

#import "AppDelegate.h"
#import "CGImageInspection.h"
#import "Pathfinding.h"

@implementation AppDelegate {
	
	// Flag to prevent infinite loop
	BOOL processing;
	
	// Stored array of draggable types
	NSArray *draggedTypes;
	
	// Orignial maze image
	NSImage *originalImage;
	
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	// Store types of images that can be dragged
	draggedTypes = [self.imageView.registeredDraggedTypes copy];

	// Observe change of inputImageView's image
	[self.imageView addObserver:self forKeyPath:@"image" options:0 context:NULL];
	
}

#pragma mark - Key-Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([object isEqual:self.imageView] && [keyPath isEqualToString:@"image"] && !processing) {
		[self solveMaze];
	}
}

#pragma mark - Maze solving

- (void)solveMaze {
	
	// Set flag
	processing = YES;
	
	// Get copy of user's image
	NSImage *image = self.imageView.image;
	
	originalImage = [image copy];
	
	// Disable user interaction
	[self.imageView unregisterDraggedTypes];
	
	// Hide placeholder label
	[self.placeholderLabel setHidden:YES];
	
	// Show progress indicator
	[self.progressIndicator startAnimation:self];
	
	// Hide image
	[self.imageView setImage:nil];
	
	// Process image in thread, so UI won't be blocked
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		// -------------------- Proccesing image to array grid --------------------
		
		// Init CGImageInspection with input image
		CGImageRef cgImage = [image CGImageForProposedRect:NULL context:NULL hints:nil];
		CGImageInspection *imageInspector = [CGImageInspection imageInspectionWithCGImage:cgImage];
		
		// Get Image Dimensions
		CGFloat width = CGImageGetWidth(cgImage);
		CGFloat height = CGImageGetHeight(cgImage);
		
		// Alloc pixel grid
		NSMutableArray *grid = [NSMutableArray arrayWithCapacity:height];
			
		// Coordinates of start and goal
		NSArray *start;
		NSArray *goal;
		
		// Process image pixels to grid array
		int realrow = 0;
		for (int row = 0; row < height; row++) {
			NSMutableArray *rowArray = [NSMutableArray arrayWithCapacity:width];
			for (int col = 0; col < width; col++) {
				
				CGFloat r, g, b, a;
				[imageInspector colorAt:CGPointMake(col, row) red:&r green:&g blue:&b alpha:&a];
				
				if (!start && r > 0.9 && g < 0.1 && b < 0.1) {
					// When red color, set start point
					start = @[@(realrow), @(col)];
				} else if (!goal && r < 0.1 && g > 0.9 && b < 0.1) {
					// When green color, set end point
					goal = @[@(realrow), @(col)];
				}
				
				if (r < 0.5 && g < 0.5 && b < 0.5) {
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
		
		// Draw maze
		NSSize size = NSMakeSize(width, height);
		NSImage *img = [self drawMaze:grid size:size init:start goal:goal path:nil];
		
		// Perform UI operations on main thread
		dispatch_sync(dispatch_get_main_queue(), ^{
			
			// Set output image
			[self.imageView setImage:img];
			
		});
		
		// When start or goal is not found
		if (!start || !goal) {
			
			// Perform UI operations on main thread
			dispatch_sync(dispatch_get_main_queue(), ^{
				
				NSAlert *alert = [NSAlert alertWithMessageText:@"Start or goal not found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
				[alert setAlertStyle:NSCriticalAlertStyle];
				[alert runModal];
				
				// Hide progress indicator
				[self.progressIndicator stopAnimation:self];
				
				// Allow user interaction
				[self.imageView registerForDraggedTypes:draggedTypes];
				
				// Unset flag
				processing = NO;
				
			});
			
			return;
			
		}
		
		// ----------------------------- Compute path -----------------------------
		
		Pathfinding *planning = [[Pathfinding alloc] initWithGrid:grid init:start goal:goal];
		[planning astar];
		
		NSArray *path = planning.path;
		
		// Convert array of coordinates to NSBezierPath for drawing
		
		NSBezierPath *bezierPath = [NSBezierPath bezierPath];
		for (int i = 0; i < path.count; i++) {
			CGPoint point = CGPointMake(0+([path[i][1] floatValue]), height-([path[i][0] floatValue]));
			if (i == 0) {
				[bezierPath moveToPoint:point];
			} else {
				[bezierPath lineToPoint:point];
			}
		}

		// Draw maze with solved path
		img = [self drawMaze:grid size:size init:start goal:goal path:bezierPath];
		
		// Perform UI operations on main thread
		dispatch_sync(dispatch_get_main_queue(), ^{
			
			// Set output image
			[self.imageView setImage:img];
			
			// Hide progress indicator
			[self.progressIndicator stopAnimation:self];
			
			// Allow user interaction
			[self.imageView registerForDraggedTypes:draggedTypes];
			
			// Unset flag
			processing = NO;
			
		});
		
	});
	
}

#pragma mark - Maze drawing

- (NSImage *)drawMaze:(NSArray *)grid size:(NSSize)size init:(NSArray *)init goal:(NSArray *)goal path:(NSBezierPath *)path {
	
	int height = size.height;
	
	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:size.width pixelsHigh:size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
	
	NSGraphicsContext *g = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:g];
	
	// Draw original image
	
	[originalImage drawInRect:NSMakeRect(0, 0, size.width, size.height)];
	
	// Draw path

	if (path) {
		path.lineWidth = 5;
		[[NSColor redColor] set];
		[path stroke];
	}
	
	// Draw start and goal
	
	CGFloat pointSize = 10;
	[[NSColor redColor] set];
	[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect([init[1] intValue]-(pointSize/2), height-[init[0] intValue]-(pointSize/2), pointSize, pointSize)] fill];
	[[NSColor greenColor] set];
	[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect([goal[1] intValue]-(pointSize/2), height-[goal[0] intValue]-(pointSize/2), pointSize, pointSize)] fill];
	
	[NSGraphicsContext restoreGraphicsState];
	NSImage *img = [[NSImage alloc] initWithSize:size];
	[img addRepresentation:rep];
	return img;
	
}

@end

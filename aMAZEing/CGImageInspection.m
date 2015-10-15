//
//  CGImageInspection.m
//  aMAZEing
//
//  Created by Alex Studnička on 24.09.13.
//  Copyright (c) 2013 Alex Studnička. All rights reserved.
//

#import "CGImageInspection.h"

@interface CGImageInspection ()

- (id) initWithCGImage: (CGImageRef) imageRef ;

@property (assign, nonatomic) CGContextRef  context ;
@property (assign, nonatomic) void *        pixels ;
@property (assign, nonatomic) NSUInteger    bytesPerRow ;
@property (assign, nonatomic) NSUInteger    bytesPerPixel ;

@end

@implementation CGImageInspection

@synthesize context ;
@synthesize pixels ;
@synthesize bytesPerRow ;
@synthesize bytesPerPixel ;

- (void) dealloc {
    if (self.context) {
        CGContextRelease(self.context) ;
        self.context = 0 ;
    }
	
    if (self.pixels) {
        free(self.pixels) ;
        self.pixels = 0 ;
    }
	
//    NSLog(@"CGImageInspection going away") ;
}

+ (CGImageInspection *) imageInspectionWithCGImage: (CGImageRef) imageRef {
    return [[CGImageInspection alloc] initWithCGImage:imageRef] ;
}

- (id) initWithCGImage: (CGImageRef) imageRef {
	
    if (self = [super init]) {
        CGFloat  pixelsWide = CGImageGetWidth(imageRef) ;
        CGFloat  pixelsHigh = CGImageGetHeight(imageRef) ;
		
        self.bytesPerPixel = 4 ;
        self.bytesPerRow = (pixelsWide * self.bytesPerPixel) ;
        int     bitmapByteCount   = (self.bytesPerRow * pixelsHigh) ;
		
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB() ;
		
        if (colorSpace == 0) {
            return nil ;
        }
		
        self.pixels = calloc(bitmapByteCount, 1) ;
        if (self.pixels == 0) {
            CGColorSpaceRelease(colorSpace) ;
            return nil ;
        }
		
        self.context = CGBitmapContextCreate(
											   self.pixels
											   ,   pixelsWide
											   ,   pixelsHigh
											   ,   8      // bits per component
											   ,   self.bytesPerRow
											   ,   colorSpace
											   ,   kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big) ;
		
        if (self.context == 0) {
            free(self.pixels) ;
            self.pixels = 0 ;
            CGColorSpaceRelease(colorSpace) ;
            return nil ;
        }
        CGContextDrawImage(context, (CGRect) {{0, 0}, {pixelsWide, pixelsHigh}}, imageRef) ;
        CGColorSpaceRelease(colorSpace) ;
    }
	
    return self ;
	
}

- (void) colorAt: (CGPoint) location
             red: (CGFloat *) red
           green: (CGFloat *) green
            blue: (CGFloat *) blue
           alpha: (CGFloat *) alpha {
	
    int yy = (int) location.y ;
    int xx = (int) location.x ;
	
    int byteIndex = (int)((bytesPerRow * yy) + xx * bytesPerPixel);
    unsigned char * raw = (unsigned char *) self.pixels ;
    raw += byteIndex ;
	
    *red    = ((CGFloat) (*raw++)) / 255.0f ;
    *green  = ((CGFloat) (*raw++)) / 255.0f ;
    *blue   = ((CGFloat) (*raw++)) / 255.0f ;
    *alpha  = ((CGFloat) (*raw++)) / 255.0f ;
}

@end

//
//  CGImageInspection.h
//  aMAZEing
//
//  Created by Alex Studnička on 24.09.13.
//  Copyright (c) 2013 Alex Studnička. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CGImageInspection : NSObject

+ (CGImageInspection *) imageInspectionWithCGImage: (CGImageRef) imageRef ;

- (void) colorAt: (CGPoint) location
             red: (CGFloat *) red
           green: (CGFloat *) green
            blue: (CGFloat *) blue
           alpha: (CGFloat *) alpha ;

@end
//
//  AppDelegate.h
//  aMAZEing
//
//  Created by Alex Studnička on 24.09.13.
//  Copyright (c) 2013 Alex Studnička. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSImageView *imageView;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *placeholderLabel;

- (void)solveMaze;
- (NSImage *)drawMaze:(NSArray *)grid size:(NSSize)size init:(NSArray *)init goal:(NSArray *)goal path:(NSBezierPath *)path;

@end

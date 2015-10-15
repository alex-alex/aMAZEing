//
//  Planning.m
//  AITest
//
//  Created by Alex Studnička on 22.03.13.
//  Copyright (c) 2013 Alex Studnička. All rights reserved.
//

#import "Pathfinding.h"

// Private methods
@interface Pathfinding ()
- (void)makeHeuristic;
- (NSMutableArray *)mutableArrayWithRows:(int)rows cols:(int)cols defaultValue:(float)defaultValue;
@end


@implementation Pathfinding {
	
	NSMutableArray *grid;
	NSArray *init;
	NSArray *goal;
	NSMutableArray *heuristic;
	
}

// creates an empty plan

- (id)initWithGrid:(NSArray *)_grid init:(NSArray *)_init goal:(NSArray *)_goal {
    self = [super init];
    if (self) {

        grid = [_grid mutableCopy];
        init = _init;
        goal = _goal;
		
		[self makeHeuristic];

    }
    return self;
}

// make heuristic function for a grid

- (void)makeHeuristic {
	heuristic = [self mutableArrayWithRows:(int)[grid count] cols:(int)[grid[0] count] defaultValue:0];
	for (int i = 0; i < [grid count]; i++) {
		for (int j = 0; j < [grid[0] count]; j++) {
			float val = ABS(i - [goal[0] floatValue]) + ABS(j - [goal[1] floatValue]);
			heuristic[i][j] = @(val);
		}
	}
}

// A* for searching a path to the goal

- (void)astar {
	
	NSAssert(heuristic, @"Heuristic must be defined to run A*");
	
	// internal motion parameters
	NSArray *delta = @[
		@[@(-1), @( 0)],	// go up
		@[@( 0), @(-1)],	// go left
		@[@( 1), @( 0)],	// go down
		@[@( 0), @( 1)],	// go right
	];
	
	// open list elements are of the type: [f, g, h, x, y]
	NSMutableArray *closed = [self mutableArrayWithRows:(int)[grid count] cols:(int)[grid[0] count] defaultValue:0];
	NSMutableArray *action = [self mutableArrayWithRows:(int)[grid count] cols:(int)[grid[0] count] defaultValue:0];
	
	closed[[init[0] intValue]][[init[1] intValue]] = @1;
	
	int x = [init[0] intValue];
	int y = [init[1] intValue];
	float h = [heuristic[(int)x][(int)y] floatValue];
	float g = 0;
	float f = g + h;
	
	NSMutableArray *open = [NSMutableArray arrayWithObject:@{@"f": @(f), @"g": @(g), @"h": @(h), @"x": @(x), @"y": @(y)}];
	
	BOOL found = NO;	// flag that is set when search is complete
    BOOL resign = NO;	// flag set if we can't find expand
	int count = 0;
	
	while (!found && !resign) {
		
		if (open.count == 0) {
			
			// Path not found
			
			resign = YES;
			
			self.path = nil;
			
			// Perform UI operations on main thread
			dispatch_sync(dispatch_get_main_queue(), ^{
				
				#if TARGET_OS_IPHONE
				
				UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"No path found" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				
				#else
				
				NSAlert *alert = [NSAlert alertWithMessageText:@"No path found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
				[alert setAlertStyle:NSCriticalAlertStyle];
				[alert runModal];
				
				#endif
			
			});
			
			return;
			
		} else {
			
			// Sort array
			[open sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"f" ascending:NO]]];
			
			// Pop values from array
			NSMutableDictionary *next = [open lastObject];
			[open removeLastObject];
			f = [next[@"f"] floatValue];
			g = [next[@"g"] floatValue];
			h = [next[@"h"] floatValue];
			x = [next[@"x"] intValue];
			y = [next[@"y"] intValue];
			
		}
		
		// Check if we are done
		
		if (x == [goal[0] intValue] && y == [goal[1] intValue]) {
			
			// Path found
			
			found = YES;
			
		} else {
			
			// Expand winning element and add to new open list
			
			int i = 0;
			for (NSArray *deltaAction in delta) {
				
				int x2 = x + [deltaAction[0] intValue];
				int y2 = y + [deltaAction[1] intValue];
				
				if (x2 >= 0 && x2 < [grid count] && y2 >=0 && y2 < [grid[0] count]) {
					
					if ([closed[x2][y2] intValue] == 0 && [grid[x2][y2] intValue] == 0) {
						
						float g2 = g + 1;
						float h2 = [heuristic[x2][y2] floatValue];
						float f2 = g2 + h2;
						
						[open addObject:@{@"f": @(f2), @"g": @(g2), @"h": @(h2), @"x": @(x2), @"y": @(y2)}];
						
						closed[x2][y2] = @(1);
						action[x2][y2] = @(i);
						
					}
					
				}
				
				i++;
				
			}
			
		}
		
		count++;
		
	}
	
	// Extract the path
	
	x = [goal[0] intValue];
	y = [goal[1] intValue];
	
	NSMutableArray *invpath = [NSMutableArray arrayWithObject:@[@(x), @(y)]];
	
	while (x != [init[0] intValue] || y != [init[1] intValue]) {

		int x2 = x - [delta[[action[x][y] intValue]][0] intValue];
		int y2 = y - [delta[[action[x][y] intValue]][1] intValue];
		
		x = x2;
		y = y2;
		
		[invpath addObject:@[@(x), @(y)]];
		
	}

	self.path = [NSMutableArray array];
	
	for (int i = 0; i < [invpath count]; i++) {
		[self.path addObject:invpath[[invpath count] - 1 - i]];
	}
	
}

#pragma mark - Utilities

// Alloc and create mutable 2D array

- (NSMutableArray *)mutableArrayWithRows:(int)rows cols:(int)cols defaultValue:(float)defaultValue {
	NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:rows];
	for (int row = 0; row < rows; row++) {
		NSMutableArray *tempArrayRow = [NSMutableArray arrayWithCapacity:cols];
		for (int col = 0; col < cols; col++) {
			[tempArrayRow addObject:@(defaultValue)];
		}
		[tempArray addObject:tempArrayRow];
	}
	return tempArray;
}

@end

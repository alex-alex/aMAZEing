//
//  Planning.h
//  AITest
//
//  Created by Alex Studnička on 22.03.13.
//  Copyright (c) 2013 Alex Studnička. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Pathfinding : NSObject

@property (nonatomic, strong) NSMutableArray *path;

- (id)initWithGrid:(NSArray *)grid init:(NSArray *)init goal:(NSArray *)goal;
- (void)astar;

@end

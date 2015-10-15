//
//  ParticleFilter.h
//  AITest
//
//  Created by Alex Studnička on 25.03.13.
//  Copyright (c) 2013 Alex Studnička. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Robot.h"

@interface ParticleFilter : NSObject

@property (nonatomic, strong) NSMutableArray *data;

- (id)initWithRobot:(Robot *)_robot X:(AIFloat)_x Y:(AIFloat)_y theta:(AIFloat)_theta steeringNoise:(float)_steeringNoise distanceNoise:(float)_distanceNoise measurementNoise:(float)_measurementNoise;
- (Position)getPosition;
- (void)moveAtGrid:(NSArray *)grid steering:(AIFloat)steering distance:(AIFloat)distance;
- (void)senseWithZ:(Position)Z;

@end

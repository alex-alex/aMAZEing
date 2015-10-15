//
//  ParticleFilter.m
//  AITest
//
//  Created by Alex Studnička on 25.03.13.
//  Copyright (c) 2013 Alex Studnička. All rights reserved.
//

#import "ParticleFilter.h"

@implementation ParticleFilter {
	
	//NSMutableArray *data;
	
	int N;
	
	AIFloat steeringNoise;
	AIFloat distanceNoise;
	AIFloat measurementNoise;
	
	Robot *robot;
	
}

@synthesize data = _data;

// ------------------------------------------------
// creates particle set with given initial position
// ------------------------------------------------
- (id)initWithRobot:(Robot *)_robot X:(AIFloat)_x Y:(AIFloat)_y theta:(AIFloat)_theta steeringNoise:(float)_steeringNoise distanceNoise:(float)_distanceNoise measurementNoise:(float)_measurementNoise {
    self = [super init];
    if (self) {
		
		N = 100;
		steeringNoise = _steeringNoise;
		distanceNoise = _distanceNoise;
		measurementNoise = _measurementNoise;
		
		robot = _robot;
		
		_data = [NSMutableArray array];
		
		for (int i = 0; i < N; i++) {
			Robot *r = [Robot new];
			[r setX:_x y:_y orientation:_theta];
//			[r setX:arc4random_uniform(20) y:arc4random_uniform(20) orientation:arc4random_uniform(2*M_PI)];
			[r setSteeringNoise:_steeringNoise distanceNoise:_distanceNoise measurementNoise:_measurementNoise];
			[_data addObject:r];
		}

    }
    return self;
}

// ------------------------------------------------
// extract position from a particle set
// ------------------------------------------------
- (Position)getPosition {
	
	AIFloat x = 0.0;
	AIFloat y = 0.0;
	AIFloat orientation = 0.0;
	
	Robot *firstRobot = _data[0];
	
	for (Robot *r in _data) {
		x += r.position.x;
		y += r.position.y;
		// orientation is tricky because it is cyclic. By normalizing
		// around the first particle we are somewhat more robust to
		// the 0=2pi problem
		orientation += (fmod(r.position.orientation - firstRobot.position.orientation + M_PI, 2.0 * M_PI) + firstRobot.position.orientation - M_PI);
	}
	
//	NSLog(@"X: %g = %g", x, x/N);
//	NSLog(@"Y: %g = %g", y, y/N);
//	NSLog(@"O: %g = %g", orientation, orientation/N);
	
	Position position;
	position.x = x / N;
	position.y = y / N;
	position.orientation = orientation / N;
	return position;
	
}

// ------------------------------------------------
// motion of the particles
// ------------------------------------------------
- (void)moveAtGrid:(NSArray *)grid steering:(AIFloat)steering distance:(AIFloat)distance {
	for (Robot *r in _data) {
//		[r moveAtGrid:grid steering:steering distance:distance];
		[r setX:RANDOM_GAUSS(robot.position.x, 0.1) y:RANDOM_GAUSS(robot.position.y, 0.1) orientation:RANDOM_GAUSS(robot.position.orientation, 0.1)];
	}
}

// ------------------------------------------------
// sensing and resampling
// ------------------------------------------------
- (void)senseWithZ:(Position)Z {
	return;

	NSMutableArray *w = [NSMutableArray arrayWithCapacity:_data.count];
		
	for (Robot *r in _data) {
		[w addObject:@([r measurementProbability:Z])];
	}

	// resampling (careful, this is using shallow copy)
	NSMutableArray *p3 = [NSMutableArray arrayWithCapacity:_data.count];
	int index = arc4random_uniform(N);
	AIFloat beta = 0.0;
	AIFloat mw = [[w valueForKeyPath:@"@max.floatValue"] floatValue];
	
	for (int i = 0; i < N; i++) {
		beta += arc4random_uniform(mw*2);
		while (beta > [w[index] floatValue]) {
			beta -= [w[index] floatValue];
			index = fmodf(index+1, N);
		}
		[p3 addObject:_data[index]];
	}
	
	_data = p3;
	
}

@end

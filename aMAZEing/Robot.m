//
//  Robot.m
//  AITest
//
//  Created by Alex Studnička on 24.03.13.
//  Copyright (c) 2013 Alex Studnička. All rights reserved.
//

#import "Robot.h"

@implementation Robot {

	Position position;
	AIFloat length;
	AIFloat steering_noise;
	AIFloat distance_noise;
	AIFloat measurement_noise;
	
}

@synthesize numCollisions = _numCollisions;
@synthesize numSteps = _numSteps;

// ------------------------------------------------
// creates robot and initializes location/orientation to 0, 0, 0
// ------------------------------------------------
- (id)init {
    self = [super init];
    if (self) {

		[self setX:0.0 y:0.0 orientation:0.0];
		[self setSteeringNoise:0.0 distanceNoise:0.0 measurementNoise:0.0];
		length					= 0.5;
		_numCollisions			= 0;
		_numSteps				= 0;
		
    }
    return self;
}

// ------------------------------------------------
// sets a robot coordinate
// ------------------------------------------------
- (Position)position {
	return position;
}

- (void)setX:(AIFloat)new_x y:(AIFloat)new_y orientation:(AIFloat)new_orientation {
	position.x = new_x;
	position.y = new_y;
	position.orientation = fmod(new_orientation, 2.0 * M_PI);
}

// ------------------------------------------------
// sets the noise parameters
// ------------------------------------------------
- (void)setSteeringNoise:(AIFloat)_steeringNoise distanceNoise:(AIFloat)_distanceNoise measurementNoise:(AIFloat)_measurementNoise {
	// makes it possible to change the noise parameters
	// this is often useful in particle filters
	steering_noise		= _steeringNoise;
	distance_noise		= _distanceNoise;
	measurement_noise	= _measurementNoise;
}

// ------------------------------------------------
// checks of the robot pose collides with an obstacle,
// or is too far outside the plane
// ------------------------------------------------
- (BOOL)checkCollision:(NSArray *)grid {
	
	for (int i = 0; i < [grid count]; i++) {
		for (int j = 0; j < [grid[0] count]; j++) {
			if ([grid[i][j] intValue] == 1) {
				AIFloat dist = sqrt(pow((position.x-j), 2) + pow((position.y-i), 2));
				if (dist < (length/2)) { //0.5+
					_numCollisions++;
					return NO;
				}
			}
		}
	}
	
	return YES;
	
}

- (BOOL)checkGoal:(Position)goal withTreshold:(AIFloat)treshold {
	treshold = (treshold == 0) ? length : treshold;
	AIFloat dist = sqrt(pow((goal.x-position.x), 2) + pow((goal.y-position.y), 2));
	return dist < treshold;
}

// ------------------------------------------------
// steering = front wheel steering angle, limited by max_steering_angle
// distance = total distance driven, must be non-negative
// ------------------------------------------------
- (void)moveAtGrid:(NSArray *)grid steering:(AIFloat)steering distance:(AIFloat)distance {
	
	AIFloat tolerance = 0.001;
	AIFloat maxSteeringAngle = M_PI_4;
	
	if (steering > maxSteeringAngle) {
		steering = maxSteeringAngle;
	}
	
	if (steering < -maxSteeringAngle) {
		steering = -maxSteeringAngle;
	}
	
	if (distance < 0.0) {
		distance = 0.0;
	}

	// apply noise
	steering = RANDOM_GAUSS(steering, steering_noise);
	distance = RANDOM_GAUSS(distance, distance_noise);
	
	// Execute motion
	AIFloat turn = tan(steering) * distance / length;
	
	if (ABS(turn) < tolerance) {
		
		// approximate by straight line motion
		
		position.x += (distance * cos(position.orientation));
		position.y += (distance * sin(position.orientation));
		position.orientation =  fmod(position.orientation + turn, 2.0 * M_PI);
		
	} else {
		
		// approximate bicycle model for motion
		
		AIFloat radius = distance / turn;
		AIFloat cx = position.x - (sin(position.orientation) * radius);
		AIFloat cy = position.y + (cos(position.orientation) * radius);
		position.orientation =  fmod(position.orientation + turn, 2.0 * M_PI);
		position.x = cx + (sin(position.orientation) * radius);
		position.y = cy - (cos(position.orientation) * radius);
		
	}
	
	_numSteps++;
	
}

- (Position)sense {
	Position sensedPosition;
	sensedPosition.x = RANDOM_GAUSS(position.x, measurement_noise);
	sensedPosition.y = RANDOM_GAUSS(position.y, measurement_noise);
//	NSLog(@"%g -> %g", position.x, sensedPosition.x);
//	NSLog(@"%g -> %g", position.y, sensedPosition.y);
	return sensedPosition;
}

// ------------------------------------------------
// computes the probability of a measurement
// ------------------------------------------------
- (AIFloat)measurementProbability:(Position)measurement {
	
	// compute errors
	AIFloat error_x = measurement.x - position.x;
	AIFloat error_y = measurement.y - position.y;
	
//	NSLog(@"%g - %g = %g", measurement.x, position.x, error_x);
//	NSLog(@"%g - %g = %g", measurement.y, position.y, error_y);

	// calculate Gaussian
	AIFloat error = exp(- pow(error_x, 2) / pow(measurement_noise, 2) / 2.0) / sqrt(2.0 * M_PI * pow(measurement_noise, 2));
	
//	NSLog(@"error: %g", error);
	
	error *= exp(- pow(error_y, 2) / pow(measurement_noise, 2) / 2.0) / sqrt(2.0 * M_PI * pow(measurement_noise, 2));
	
//	NSLog(@"error: %g", error);
//	NSLog(@"-----------------------");
	
	return error;
	
}

- (NSString *)description {
	return [NSString stringWithFormat:@"Robot [x=%.5f, y=%.5f, orient=%.5f]", position.x, position.y, position.orientation];
}

@end

//
//  Robot.h
//  AITest
//
//  Created by Alex Studnička on 24.03.13.
//  Copyright (c) 2013 Alex Studnička. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef float AIFloat;

typedef struct {
	AIFloat x;
	AIFloat y;
	AIFloat orientation;
} Position;

@interface Robot : NSObject

@property (nonatomic, readonly) Position position;
@property (nonatomic, readonly) int numCollisions;
@property (nonatomic, readonly) int numSteps;

- (void)setX:(AIFloat)x y:(AIFloat)y orientation:(AIFloat)orientation;
- (void)setSteeringNoise:(AIFloat)steeringNoise distanceNoise:(AIFloat)distanceNoise measurementNoise:(AIFloat)measurementNoise;
- (BOOL)checkCollision:(NSArray *)grid;
- (BOOL)checkGoal:(Position)goal withTreshold:(AIFloat)treshold;
- (void)moveAtGrid:(NSArray *)grid steering:(AIFloat)steering distance:(AIFloat)distance;
- (Position)sense;
- (AIFloat)measurementProbability:(Position)measurement;

@end

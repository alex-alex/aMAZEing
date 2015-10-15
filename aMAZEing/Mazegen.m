//
//  Mazegen.m
//  aMAZEing
//
//  Created by Alex Studnicka on 21/11/13.
//  Copyright (c) 2013 Alex Studnička. All rights reserved.
//

#import "Mazegen.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define WIDTH 15
#define HEIGHT 5

#define UP 0
#define RIGHT 1
#define DOWN 2
#define LEFT 3

#define cell_empty(a) (!(a)->up && !(a)->right && !(a)->down && !(a)->left)

typedef struct {
    unsigned int up      : 1;
    unsigned int right   : 1;
    unsigned int down    : 1;
    unsigned int left    : 1;
    unsigned int path    : 1;
    unsigned int visited : 1;
} cell_t;
typedef cell_t *maze_t;

@implementation Mazegen {
	int width, height;
	maze_t maze;
}

- (id)initWithSize:(NSSize)size {
	self = [super init];
	if (self) {
		width = size.width;
		height = size.height;
		[self setup];
	}
	return self;
}

- (void)setup {
	
	if (width <= 0 || height <= 0) {
		NSLog(@"Illegal width or height value!");
		return;
	}
	
	maze = (maze_t) calloc (width * height, sizeof (cell_t));
	
	if (maze == NULL) {
		NSLog(@"Cannot allocate memory!");
		return;
	}
	
	[self create];
	[self print];
	
//	printf("\n");
//	[self solve];
//	[self print];

//	free(maze);
	
}

- (void)create {
	
	maze_t mp, maze_top;
    char paths [4];
    int visits, directions;
	
    visits = width * height - 1;
    mp = maze;
    maze_top = mp + (width * height) - 1;
	
    while (visits) {
        directions = 0;
		
        if ((mp - width) >= maze && cell_empty (mp - width))
            paths [directions++] = UP;
        if (mp < maze_top && ((mp - maze + 1) % width) && cell_empty (mp + 1))
            paths [directions++] = RIGHT;
        if ((mp + width) <= maze_top && cell_empty (mp + width))
            paths [directions++] = DOWN;
        if (mp > maze && ((mp - maze) % width) && cell_empty (mp - 1))
            paths [directions++] = LEFT;
		
        if (directions) {
            visits--;
            directions = ((unsigned) rand () % directions);
			
            switch (paths [directions]) {
                case UP:
                    mp->up = TRUE;
                    (mp -= width)->down = TRUE;
                    break;
                case RIGHT:
                    mp->right = TRUE;
                    (++mp)->left = TRUE;
                    break;
                case DOWN:
                    mp->down = TRUE;
                    (mp += width)->up = TRUE;
                    break;
                case LEFT:
                    mp->left = TRUE;
                    (--mp)->right = TRUE;
                    break;
                default:
                    break;
            }
        } else {
            do {
                if (++mp > maze_top)
                    mp = maze;
            } while (cell_empty (mp));
        }
    }
	
}

- (void)solve {
	
	maze_t *stack, mp = maze;
    int sp = 0;
	
    stack = (maze_t *) calloc (width * height, sizeof (maze_t));
    if (stack == NULL) {
		NSLog(@"Cannot allocate memory!");
		return;
    }
    (stack [sp++] = mp)->visited = YES;
	
    while (mp != (maze + (width * height) - 1)) {
		
        if (mp->up && !(mp - width)->visited)
            stack [sp++] = mp - width;
        if (mp->right && !(mp + 1)->visited)
            stack [sp++] = mp + 1;
        if (mp->down && !(mp + width)->visited)
            stack [sp++] = mp + width;
        if (mp->left && !(mp - 1)->visited)
            stack [sp++] = mp - 1;
		
        if (stack [sp - 1] == mp)
            --sp;
		
        (mp = stack [sp - 1])->visited = YES;
    }
    while (sp--)
        if (stack[sp]->visited)
            stack[sp]->path = TRUE;
	
    free (stack);
	
}

- (void)print {
	
//	int realrow = 0;
//	for (int row = 0; row < height*3; row++) {
//		for (int col = 0; col < width; col++) {
//			cell_t *obj = maze+((realrow*width)+col);
//			if (row%3 == 0) {
//				if (obj->up || (realrow == 0 && col == 0)) {
//					printf("X X");
//				} else {
//					printf("XXX");
//				}
//			} else if (row%3 == 1) {
//				if (obj->left) {
//					printf(" ");
//				} else {
//					printf("X");
//				}
//				
//				printf(" ");
//				
//				if (obj->right) {
//					printf(" ");
//				} else {
//					printf("X");
//				}
//			} else if (row%3 == 2) {
//				if (obj->down || (realrow == height-1 && col == width-1)) {
//					printf("X X");
//				} else {
//					printf("XXX");
//				}
//			}
//		}
//		printf("\n");
//		if (row%3 == 2) realrow++;
//	}
	
	int w, h;
    char *line, *lp;
	
    line = (char *) calloc ((width + 1) * 2, sizeof (char));
    if (line == NULL) {
        (void) fprintf (stderr,"Cannot allocate memory!\n");
        exit (EXIT_FAILURE);
    }
    maze->up = YES;
    (maze + (width * height) - 1)->down = YES;
	
    for (lp = line, w = 0; w < width; w++) {
        *lp++ = '+';
        if ((maze + w)->up)
            *lp++ = ((maze + w)->path) ? '.' : ' ';
        else
            *lp++ = '-';
    }
    *lp++ = '+';
    (void) puts (line);
    for (h = 0; h < height; h++) {
        for (lp = line, w = 0; w < width; w++) {
            if ((maze + w)->left)
                *lp++ = ((maze + w)->path && (maze + w - 1)->path) ? '.' : ' ';
            else
                *lp++ = '|';
            *lp++ = ((maze + w)->path) ? '.' : ' ';
        }
        *lp++ = '|';
        (void) puts (line);
        for (lp = line, w = 0; w < width; w++) {
            *lp++ = '+';
            if ((maze + w)->down)
                *lp++ = ((maze + w)->path && (h == height - 1 ||
											  (maze + w + width)->path)) ? '.' : ' ';
            else
				
                *lp++ = '-';
        }
        *lp++ = '+';
        (void) puts (line);
        maze += width;
    }
    free (line);
	
}

@end

//
//  TTVScrubSlider.m
//  TikiTV2
//
//  Created by Jesse Hammons on 11/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TTVScrubSlider.h"


@implementation TTVScrubSlider

- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }

- (void)mouseDown:(NSEvent*)event {
	[[self delegate] startScrub];
	[super mouseDown:event];
	[[self delegate] endScrub];
}

- (void)startScrub{}
- (void)endScrub{}


@end

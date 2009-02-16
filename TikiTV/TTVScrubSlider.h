//
//  TTVScrubSlider.h
//  TikiTV2
//
//  Created by Jesse Hammons on 11/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TTVScrubSlider : NSSlider {
	id _delegate;
}
- (void)setDelegate:(id)delegate;
-(id)delegate;

- (void)startScrub;
- (void)endScrub;

@end

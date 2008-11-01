//
//  VSPipe.h
//  TikiTV
//
//  Created by Jesse Hammons on 11/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
	VSQueueConditionNoneAvailable,
	VSQueueConditionSomeAvailable
};

@interface VSBufferQueue : NSObject
{
	NSMutableArray *_queue;
	NSConditionLock *_queueCondition;
	NSLock *_lock;
}

- (int)count;
- (void)enqueue:(id)buffer;
- (id)dequeue;
- (BOOL)objectsAvailable;

@end


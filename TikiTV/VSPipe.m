//
//  VSPipe.m
//  TikiTV
//
//  Created by Jesse Hammons on 11/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "VSPipe.h"

@implementation VSBufferQueue

- (id)init 
{
	self = [super init];
	if (self != nil) {
		_queue = [[NSMutableArray alloc] init];
		_queueCondition = [[NSConditionLock alloc] initWithCondition:VSQueueConditionNoneAvailable];
		_lock = [[NSLock alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_lock release];
	[_queueCondition release];
	[_queue release];
	[super dealloc];
}

- (int)count
{
	[_lock lock];
	
	int count =  [_queue count];
	
	[_lock unlock];
	
	return count;
}

- (void)enqueueAtFront:(id)buffer
{
	[_lock lock];
	
	[_queue insertObject:buffer atIndex:0];
//	NSLog(@"0x%X, 0x%X enqueing 0x%X, count is %d", (int)[NSThread currentThread], (int)self, (int)buffer, [_queue count]);	
	
//	if ([_queueCondition tryLockWhenCondition:VSQueueConditionNoneAvailable]) {
//		[_queueCondition unlockWithCondition:VSQueueConditionSomeAvailable];
//	}

	NSDate *next = (NSDate*)CFDateCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent());
	if ([_queueCondition lockWhenCondition:VSQueueConditionNoneAvailable beforeDate:next]) {
		[_queueCondition unlockWithCondition:VSQueueConditionSomeAvailable];
	}
	CFRelease((CFDateRef)next);

	[_lock unlock];
}

- (void)enqueue:(id)buffer
{
	[_lock lock];
	
	[_queue addObject:buffer];
//	NSLog(@"0x%X, 0x%X enqueing 0x%X, count is %d", (int)[NSThread currentThread], (int)self, (int)buffer, [_queue count]);	
	
//	if ([_queueCondition tryLockWhenCondition:VSQueueConditionNoneAvailable]) {
//		[_queueCondition unlockWithCondition:VSQueueConditionSomeAvailable];
//	}

	NSDate *next = (NSDate*)CFDateCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent());
	if ([_queueCondition lockWhenCondition:VSQueueConditionNoneAvailable beforeDate:next]) {
		[_queueCondition unlockWithCondition:VSQueueConditionSomeAvailable];
	}
	CFRelease((CFDateRef)next);

	[_lock unlock];
}

- (id)dequeue
{
	NSData *buffer = nil;
	[_queueCondition lockWhenCondition:VSQueueConditionSomeAvailable];
	[_lock lock];
	
	if ([_queue count] != 0) {
		buffer = [_queue objectAtIndex:0];
		[_queue removeObjectAtIndex:0];
	}

	[_queueCondition unlockWithCondition:[_queue count] == 0 ? VSQueueConditionNoneAvailable : VSQueueConditionSomeAvailable];
	[_lock unlock];
	
	return buffer;
}

- (BOOL)objectsAvailable {
	BOOL available;
	[_lock lock];
	available = [_queueCondition condition] == VSQueueConditionSomeAvailable;
	[_lock unlock];
	return available;
}




@end

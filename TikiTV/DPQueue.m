//
//  DPQueue.m
//  
//
//  Created by Ofri Wolfus on 09/08/07.
//  Copyright 2007 Ofri Wolfus. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//  
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. Neither the name of Ofri Wolfus nor the names of his contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "DPQueue.h"


@implementation DPQueue

- (id)init {
	if ((self = [super init])) {
		_DPQueueNode *node = calloc(1, sizeof(_DPQueueNode));
		
		_refCount = 1;
		node->next = NULL;
		head = node;
		tail = node;
		h_lock = OS_SPINLOCK_INIT;
		t_lock = OS_SPINLOCK_INIT;
		count = 0;
	}
	
	return self;
}

- (void)dealloc {
	// Free all nodes
	while ([self dequeue]);
	// Free the extra node
	free(head);
	[super dealloc];
}

// We need thread-safe ref counting.
// This might actually be faster than NSObject's implementation.
- (id)retain {
	OSAtomicIncrement32Barrier(&_refCount);
	return self;
}

- (void)release {
	if (OSAtomicDecrement32Barrier(&_refCount) == 0)
		[self dealloc];
}

- (unsigned)retainCount {
	OSMemoryBarrier();
	return (unsigned)_refCount;
}

- (void)enqueue:(id)obj {
	_DPQueueNode *node = malloc(sizeof(_DPQueueNode));
	
	node->value = [obj retain];
	node->next = NULL;
	
	OSSpinLockLock(&t_lock);
	tail->next = node;
	tail = node;
	OSAtomicIncrement32(&count);
	OSSpinLockUnlock(&t_lock);
}

- (id)dequeue {
	id result = nil;
	_DPQueueNode *node, *new_head;
	
	OSSpinLockLock(&h_lock);
	node = head;
	new_head = node->next;
	
	if (__builtin_expect(!new_head, 0)) {
		OSSpinLockUnlock(&h_lock);
		return nil;
	}
	
	result = new_head->value;
	head = new_head;
	OSAtomicDecrement32(&count);
	OSSpinLockUnlock(&h_lock);
	free(node);
	return [result autorelease];
}

- (unsigned)count {
	OSMemoryBarrier();
	return (unsigned)count;
}

@end

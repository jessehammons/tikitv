//
//  DPQueue.h
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

#import <Foundation/Foundation.h>
#include <libkern/OSAtomic.h>	// For OSSpinLock


// Private
typedef struct {
	id value;
	void *next;
} _DPQueueNode;

/*!
 * @abstract A thread-safe queue.
 */
@interface DPQueue : NSObject {
	// Need our own ref-counting as Apple's implementation itsn't thread satfe
	int32_t _refCount;
	_DPQueueNode *head, *tail;
	OSSpinLock h_lock, t_lock;
	int32_t count;
}

/*!
 * @abstract Adds <code>obj</code> to the queue.
 */
- (void)enqueue:(id)obj;

/*!
 * @abstract Pops the topmost object in the queue and returns it.
 * @discussion Returns <code>nil</code> if the receiver is empty.
 */
- (id)dequeue;

/*!
 * @abstract Returns the number of objects in the receiver.
 */
- (unsigned)count;

@end

//
//  TTVCore.h
//  TikiTV2
//
//  Created by Jesse Hammons on 8/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define TTV_KVC_SETX(name, ivar, val) ([name setValue:val forKey:[@"_" stringByAppendingString:@#ivar]])
#define TTV_KVC_SUPER_SET(ivar, val) (TTV_KVC_SETX(super, ivar, val))
#define TTV_KVC_SET(ivar, val) (TTV_KVC_SETX(self, ivar, val))
#define TTV_KVC_GET(ivar) ([self valueForKey:@#ivar])
#define TTV_INVALIDATE(ptr) ptr = (void*)__LINE__
#define TTV_RELEASE(obj) [obj release]; TTV_INVALIDATE(obj)
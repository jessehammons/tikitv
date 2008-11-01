#import "TTVImageBrowserView.h"

@class IKImageBrowserCell;

@interface TTVImageBrowserCell : NSCell
{
}
@end

@implementation TTVImageBrowserCell
- (id)initImageCell:(NSImage *)anImage {
	[self poseAsClass:[IKImageBrowserCell class]];
	self = [super initImageCell:anImage];
	if (self != nil) {
	}
	return nil;
}

@end

@interface TTVImageBrowserViewPrivate : NSObject
- (NSRect)cellFrameAtIndex:(int)i;
@end

@implementation TTVImageBrowserView

- (id)initWithFrame:(NSRect)frame {
	self = [super initwithFrame:frame];
	if (self != nil) {
		NSLog(@"dude");
	}
	return self;
}

- (id)initWithCoder:(NSCoder*)coder {
	self = [super initWithCoder:coder];
	if (self != nil) {
		NSLog(@"dude");
	}
	return self;
}

- (NSRect)cellFrameAtIndex:(int)i {
	return [((TTVImageBrowserViewPrivate*)super) cellFrameAtIndex:i];
}

- (Class)cellClass {
	return [TTVImageBrowserCell class];
}

@end

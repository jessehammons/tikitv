#import "VSWindow.h"

@implementation VSWindow

- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)aScreen
{
	/* disable constraints */
	return frameRect;
}

- (void)setFullscreen:(BOOL)fullscreen
{
	if (fullscreen) {
		if (!_isFullscreen) {
			_savedFrame = [self frame];
			_savedLevel = [self level];
			NSRect frame = [self frameRectForContentRect:[[self screen] frame]];
			frame = NSInsetRect(frame, -20, -20);
			[self setLevel:NSScreenSaverWindowLevel];
			[self setFrame:frame display:NO animate:YES];
			_isFullscreen = YES;
		}
	}
	else {
		if (_isFullscreen) {
			[self setLevel:_savedLevel];
			[self setFrame:_savedFrame display:YES animate:YES];
			_isFullscreen = NO;			
		}
	}
}

- (BOOL)handleEvent:(NSEvent*)event {
	return NO;
}

- (BOOL)isFullscreen
{
	return _isFullscreen;
}

- (void)noResponderFor:(SEL)eventSelector {
//	NSLog(@"VSWindow: no responder for %@", NSStringFromSelector(eventSelector));
}


- (void)sendEvent:(NSEvent *)event {
	if ([[self firstResponder] isKindOfClass:[NSTextView class]]) {
		return [super sendEvent:event];
	}
	if ([[self delegate] handleEvent:event] == NO) {
		return [super sendEvent:event];
	}
}

@end

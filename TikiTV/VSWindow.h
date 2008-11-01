/* VSWindow */

#import <Cocoa/Cocoa.h>

@interface VSWindow : NSWindow
{
	BOOL _isFullscreen;
	NSRect _savedFrame;
	int _savedLevel;
}

- (void)setFullscreen:(BOOL)fullscreen;
- (BOOL)isFullscreen;

@end

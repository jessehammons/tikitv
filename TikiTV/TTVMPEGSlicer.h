/* TTVMPEGSlicer */

#import <Cocoa/Cocoa.h>

#import "TTVAppDelegate.h"
#import "TTVScrubSlider.h"

@class VSOpenGLView;

@interface TTVMPEGSlicer : NSObject
{
	IBOutlet NSTextField *_frameNumberTextField;
	IBOutlet TTVScrubSlider *_markInSlider;
	IBOutlet NSTextField *_markInTextField;
	IBOutlet NSTextField *_markOutTextField;
	IBOutlet NSTextField *_modeTextField;
	IBOutlet VSOpenGLView *_controlsView;
	IBOutlet NSTableView *_clipsTableView;
	
	TTVDecoderThread *_decoder;
	BOOL _initialized;
	BOOL _paused;
	TTVClipList *_clips;
	BOOL _scrubbing;
	NSArray *_modes;
	int _currentMode;
}

- (TTVClipList *)clips;

- (IBAction)addClip:(id)sender;
- (IBAction)splitMedia:(id)sender;

@end

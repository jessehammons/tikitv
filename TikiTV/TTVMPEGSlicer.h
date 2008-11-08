/* TTVMPEGSlicer */

#import <Cocoa/Cocoa.h>

#import "TTVAppDelegate.h"
@class VSOpenGLView;

@interface TTVMPEGSlicer : NSObject
{
	IBOutlet NSTextField *_frameNumberTextField;
	IBOutlet NSSlider *_markInSlider;
	IBOutlet NSTextField *_markInTextField;
	IBOutlet NSSlider *_markOutSlider;
	IBOutlet NSTextField *_markOutTextField;	
	IBOutlet VSOpenGLView *_controlsView;
	IBOutlet NSTableView *_clipsTableView;
	
	TTVDecoderThread *_decoder;
	BOOL _initialized;
	BOOL _paused;
	TTVClipList *_clips;
}

- (TTVClipList *)clips;

- (IBAction)addClip:(id)sender;

@end

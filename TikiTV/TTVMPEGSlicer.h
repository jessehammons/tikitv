/* TTVMPEGSlicer */

#import <Cocoa/Cocoa.h>

#import "TTVAppDelegate.h"
@class VSOpenGLView;

@interface TTVMPEGSlicer : NSObject
{
	IBOutlet NSSlider *_markInSlider;
	IBOutlet NSTextField *_markInTextField;
	IBOutlet NSSlider *_markOutSlider;
	IBOutlet NSTextField *_markOutTextField;	
	IBOutlet VSOpenGLView *_controlsView;
	
//	VSDecoder *_decoder;
	TTVDeck *_deck;
	BOOL _initialized;
	BOOL _paused;
}
@end

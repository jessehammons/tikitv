/* TTVAppDelegate */

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

#import "VSWindow.h"
#import "TTVDecoding.h"


@interface TTVTableView : NSTableView
@end

@interface TTVCommandView : NSView
{
	NSScrollView *_scrollView;
    TTVTableView *_tableView;
	NSTextField *_textfield;
	
	id /* weak */_delegate;
	
	NSArray *_matches;
	int _streamIndex;	
}
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (void)setStreamIndex:(int)index;
- (int)streamIndex;
- (void)setHighlighted:(BOOL)hilighted;
- (NSString*)matchForRow:(int)row;
- (NSArray*)match:(NSString*)string;
- (int)selectedRow;
- (void)setSelectedRow:(int)row;
- (NSString*)matchForSelectedRow;

@end

@interface TTVPictureSource : NSObject
{
	NSMutableArray *_decoders;
	NSMutableArray *_streams;
	NSMutableArray *_swizzle;
}

- (id)initWithFilenames:(NSArray*)names streams:(NSArray*)streams;
- (TTVDecoderThread*)decoder:(int)index;
- (TTVVideoStream*)streamAtIndex:(int)index;
- (int)streamCount;
- (void)preroll;
- (BOOL)play;
- (void)allDone;
- (void)createBookmark:(NSString*)mark;
- (void)loadFromBookmark:(NSString*)mark;
- (void)swizzleStream:(int)i1 newIndex:(int)i2;

@end


@interface TTVDeck : NSObject
{
	TTVPictureSource *_pictureSource;
	TTVRenderer *_renderer;
}
- (id)initWithFilenames:(NSArray*)filenames;
- (void)drawOutput:(NSRect)rect context:(NSOpenGLContext*)context;
- (TTVPictureSource*)pictureSource;
- (void)preroll;
- (BOOL)play;
- (void)advance;
- (void)setInputFilenames:(NSArray*)filenames;
- (void)allDone;
@end



@interface TTVApplication : NSApplication
{
}
@end

@interface TTVAppDelegate : NSObject
{
	IBOutlet NSOpenGLView *_controlsView;
	NSWindow *_mainWindow;
	
	NSMutableArray *_decks;
	IBOutlet IKImageBrowserView *_imageBrowser;
	NSMutableArray *_imagePaths;
	NSArray *_imageBrowserItems;
	
	BOOL _initialized;
	
	NSMutableArray *_timings;
	CFAbsoluteTime _lastChangeTime;
	
	int _outputDeckIndex;
	
	NSMutableArray *_commandViews;
	int _commandViewIndex;
	IBOutlet NSTextField *_modeTextfield;
	id _mode;
	NSMutableDictionary *_modeMap;
	BOOL _paused;
	BOOL _affectOutput;
	BOOL _exitRenderThread;
}

- (void)exitFullscreen;
- (void)enterFullscreen;

- (NSArray*)decks;
- (IBAction)toggleFullscreen:(id)sender;

- (TTVDeck*)previewDeck;
- (TTVDeck*)outputDeck;

- (void)advance;

- (void)setMode:(id)mode;
- (id)mode;

- (void)activateCommandView:(BOOL)setFirstResponder;
- (void)activateNextCommandView:(BOOL)setFirstResponder;
- (TTVCommandView*)activeCommandView;
- (void)commandView:(TTVCommandView*)view executeRow:(int)row;
- (NSArray*)commandView:(TTVCommandView*)view match:(NSString*)string;
- (void)commandView:(TTVCommandView*)view moveLeft:(id)sender;
- (void)commandView:(TTVCommandView*)view moveRight:(id)sender;

- (void)toggleDeck:(id)sender;
- (void)togglePause:(id)sender;
- (void)toggleOutputActive:(id)sender;
- (void)reloadClipSequence:(id)sender;
- (void)updateSequenceSelection:(NSNumber*)newIndex;

@end

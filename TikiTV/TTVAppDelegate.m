
#import "TTVAppDelegate.h"
#import "VSFileLibrary.h"

#import <OpenGL/CGLMacro.h>
#import <OpenGL/gluMacro.h>

#import <mach/mach_init.h>
#import <mach/thread_policy.h>
kern_return_t   thread_policy_set(thread_t                                        thread, thread_policy_flavor_t          flavor, thread_policy_t                         policy_info, mach_msg_type_number_t          count);

int set_realtime(int, int, int);

#import <sched.h>
#import <pthread.h>

/* This is a bunch of black macgic that appears get us good scheduling in the kernal */

int set_realtime(int period, int computation, int constraint) {
    struct thread_time_constraint_policy ttcpolicy;
    int ret;
	
    ttcpolicy.period=period; // HZ/160
    ttcpolicy.computation=computation; // HZ/3300;
    ttcpolicy.constraint=constraint; // HZ/2200;
    ttcpolicy.preemptible=0;
	NSLog(@"period %d, computation %d, constraint %d\n", period, computation, constraint);
    if ((ret=thread_policy_set(mach_thread_self(),
							   THREAD_TIME_CONSTRAINT_POLICY, (thread_policy_t)&ttcpolicy,
							   THREAD_TIME_CONSTRAINT_POLICY_COUNT)) != KERN_SUCCESS) {
		fprintf(stderr, "set_realtime() failed %d. \n", ret);
		return 0;
    }
    //return 1;
	struct sched_param param;
	//SCHED_FIFO
	//SCHED_RR
	param.sched_priority = sched_get_priority_max(SCHED_RR);
	int result = pthread_setschedparam(pthread_self(), SCHED_RR , &param);
	NSLog(@"pthread setsched result %d", result);
	return 1;
}


@interface TTVMode : NSObject { }
- (BOOL)handleEvent:(NSEvent*)event;
- (void)enterMode;
- (void)leaveMode;
- (id)delegate;
- (NSArray*)match:(NSString*)string;
- (void)executeRow:(int)row;
- (void)moveLeft;
- (void)moveRight;
- (NSString*)displayName;
@end

@implementation TTVMode
- (BOOL)handleEvent:(NSEvent*)event {
	return NO;
}
- (NSArray*)match:(NSString*)string {
	return [NSArray array];
}
- (void)moveLeft {}
- (void)moveRight {}
- (void)enterMode {}
- (void)leaveMode {}
- (void)executeRow:(int)row {}
- (id)delegate {
	return [[NSApplication sharedApplication] delegate];
}
- (NSString*)displayName { return @"implement displayName :-)"; }
@end

@interface TTVLoadMode : TTVMode {}
@end

@implementation TTVLoadMode

- (NSString*)displayName { return @"Load:"; }

- (void)enterMode {
	[[self delegate] activateCommandView:YES];
}

- (void)moveLeft {
	int index = [[[self delegate] activeCommandView] streamIndex];
	TTVDeck *deck = [[self delegate] previewDeck];
	[[[deck pictureSource] decoder:index%3] skipBackward];
}
- (void)moveRight {
	int index = [[[self delegate] activeCommandView] streamIndex];
	TTVDeck *deck = [[self delegate] previewDeck];
	[[[deck pictureSource] decoder:index%3] skipForward];
}

- (BOOL)handleEvent:(NSEvent*)event {
	BOOL handled = [super handleEvent:event];
	if (handled == NO) {
	}
	return handled;
}

- (NSArray*)match:(NSString*)string {
	NSMutableArray *matches = [NSMutableArray array];
	int rowCount = [[VSFileLibrary library] numberOfRowsInTableView:nil];
	for(int i = 0; i < rowCount; i++) {
		NSString *filename = [[VSFileLibrary library] filenameForRow:i];
		if ([string length] == 0 || [filename rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound) {
			[matches addObject:filename];
		}
	}
	return matches;
}

- (void)executeRow:(int)row {
	int index = [[[self delegate] activeCommandView] streamIndex];
	NSString *path = [[VSFileLibrary library] pathForFilename:[[[self delegate] activeCommandView] matchForRow:row]];
	TTVDeck *deck = [[self delegate] previewDeck];
	[[[deck pictureSource] decoder:index%3] changeMediaFile:path];
	if ([[path pathExtension] isEqualToString:@"ttv_seq"]) {
		[[self delegate] reloadClipSequence:[[deck pictureSource] decoder:index%3]];
	}
}

@end

@interface TTVMarkMode : TTVMode  { }
@end

@implementation TTVMarkMode

- (NSString*)displayName { return @"Mark:"; }

- (BOOL)handleEvent:(NSEvent*)event {
	NSLog(@"event is %@", event);
	BOOL handled = [super handleEvent:event];
	if (event != nil && handled == NO) {
		if ([event type] == NSKeyDown) {
			NSString *key = [event characters];
			[[[[self delegate] previewDeck] pictureSource] createBookmark:key];
			[[self delegate] setMode:nil];
		}
	}
	return handled;
}
@end

@interface TTVRestoreMode : TTVMode { }
@end

@implementation TTVRestoreMode

- (NSString*)displayName { return @"Restore:"; }

- (BOOL)handleEvent:(NSEvent*)event {
	BOOL handled = [super handleEvent:event];
	if (event != nil && handled == NO) {
		if ([event type] == NSKeyDown) {
			NSString *key = [event characters];
			[[[[self delegate] previewDeck] pictureSource] loadFromBookmark:key];
			[[self delegate] setMode:nil];
		}
	}
	return handled;
}

@end

@interface TTVAffectOutputMode : TTVMode { }
@end

@implementation TTVAffectOutputMode

- (NSString*)displayName { return @"AffectOutput:"; }

- (BOOL)handleEvent:(NSEvent*)event {
	[[self delegate] toggleOutputActive:nil];
	[[self delegate] setMode:nil];
	return YES;
}

@end

@interface TTVMatchOutputMode : TTVMode { }
@end

@implementation TTVMatchOutputMode

- (NSString*)displayName { return @"MatchOutput:"; }

- (BOOL)handleEvent:(NSEvent*)event {
	TTVDeck *previewDeck = [[self delegate] previewDeck];
	TTVDeck *outputDeck = [[self delegate] outputDeck];
	for(int i = 0; i < 3; i++) {
		[[[previewDeck pictureSource] decoder:i] changeMediaFile:[[[outputDeck pictureSource] decoder:i] inputFilename]];
	}
	[[self delegate] setMode:nil];
	return YES;
}

@end

@interface TTVSwapChannelMode : TTVMode { }
@end

@implementation TTVSwapChannelMode

- (NSString*)displayName { return @"Swap Channel:"; }

- (BOOL)handleEvent:(NSEvent*)event {
	BOOL handled = [super handleEvent:event];
	if (event != nil && handled == NO) {
		if ([event type] == NSKeyDown) {
			TTVDeck *deck = [[self delegate] previewDeck];
			NSString *key = [event characters];
			if ([key isEqualToString:@"l"]) {
				[[deck pictureSource] swizzleStream:0 newIndex:1];
			}
			else if ([key isEqualToString:@"r"]) {
				[[deck pictureSource] swizzleStream:2 newIndex:1];
			}
			else if ([key isEqualToString:@"e"]) {
				[[deck pictureSource] swizzleStream:0 newIndex:2];
			}
			handled = YES;
			[[self delegate] setMode:nil];
		}
	}
	return handled;
}

@end


@interface TTVAdjustMode : TTVMode { }
@end

@implementation TTVAdjustMode

- (NSString*)displayName { return @"Adjust:"; }

- (void)enterMode {
	[[self delegate] activateCommandView:YES];
	[[[self delegate] activeCommandView] controlTextDidChange:nil];
}

- (BOOL)handleEvent:(NSEvent*)event {
	BOOL handled = [super handleEvent:event];
	if (handled == NO) {
	}
	return handled;
}


- (NSArray*)match:(NSString*)string {
	return [NSArray arrayWithObjects:@"bias", @"scale", @"exp", nil];
}

- (void)moveLeft {
	NSString *field = [[[self delegate] activeCommandView] matchForSelectedRow];
	NSLog(@"decrementing field %@", field);
	int index = [[[self delegate] activeCommandView] streamIndex];
	TTVDeck *deck = [[self delegate] previewDeck];
	[[[deck pictureSource] streamAtIndex:index%3] decrementField:field];
}

- (void)moveRight {
	NSString *field = [[[self delegate] activeCommandView] matchForSelectedRow];
	NSLog(@"incrementing field %@", field);
	int index = [[[self delegate] activeCommandView] streamIndex];
	TTVDeck *deck = [[self delegate] previewDeck];
	[[[deck pictureSource] streamAtIndex:index%3] incrementField:field];
}

@end


@implementation TTVApplication

#if 1
- (void) sendEvent:(NSEvent*)event
{
	//If the user pressed the [Esc] key, we need to exit	
//	if(event != nil && ([event type] == NSKeyDown) && ([event keyCode] == 0x35)) {
//	}
	BOOL handled = [[self delegate] handleEvent:event];
	if (handled == NO) {
		[super sendEvent:event];
	}	
}
#endif

@end


@implementation TTVPictureSource

- (id)initWithFilenames:(NSArray*)names streams:(NSArray*)streams {
	self = [super init];
	if (self != nil) {
		_streams = [streams retain];
		_decoders = [[NSMutableArray alloc] init];
		_swizzle = [[NSMutableArray alloc] init];
		for(int i = 0 ; i < [names count]; i++) {
//			[_decoders addObject:[[[VSDecoder alloc] initWithInputFilename:[names objectAtIndex:i] stream:[streams objectAtIndex:i]] autorelease]];
			[_decoders addObject:[[[TTVDecoderThread alloc] initWithFile:[names objectAtIndex:i] stream:[streams objectAtIndex:i]] autorelease]];
			[_swizzle addObject:[NSNumber numberWithInt:i]];
		}
	}
	return self;
}

- (void)dealloc {
	[_decoders release];
	_decoders = (void*)0x9;
	[_streams release];
	_streams = (void*)0x9;
	[super dealloc];
}

- (void)advance {
	[_streams makeObjectsPerformSelector:@selector(advance)];
}

- (void)createBookmark:(NSString*)mark {
	NSString *bookmarkPath = [[VSFileLibrary library] pathForBookmark:mark];
	NSMutableArray *files = [NSMutableArray array];
	for(int i = 0; i < [_decoders count]; i++) {
		[files addObject:[[[_decoders objectAtIndex:i] inputFilename] lastPathComponent]];
	}
	NSString *state = [files componentsJoinedByString:@","];
	[state writeToFile:bookmarkPath atomically:YES encoding:NSASCIIStringEncoding error:nil];
}

- (void)loadFromBookmark:(NSString*)mark {
	NSString *bookmarkPath = [[VSFileLibrary library] pathForBookmark:mark];
	NSString *state = [NSString stringWithContentsOfFile:bookmarkPath];
	if ([state length] == 0) {
		NSLog(@"WARNING: no bookmark for key: %@", mark);
		return;
	}
	NSArray *files = [state componentsSeparatedByString:@","];
	for(int i = 0; i < [_decoders count]; i++) {
		NSString *path = [[VSFileLibrary library] pathForFilename:[files objectAtIndex:i]];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
			NSLog(@"WARNING: files does not exist: %@", path);
			continue;
		}
		[[_decoders objectAtIndex:i] changeMediaFile:path];
	}
}

- (void)swizzleStream:(int)i1 newIndex:(int)i2 {

	id save = [_swizzle objectAtIndex:i1];
	id swap = [_swizzle objectAtIndex:i2];
	[_swizzle replaceObjectAtIndex:i1 withObject:swap];
	[_swizzle replaceObjectAtIndex:i2 withObject:save];

	save = [[_decoders objectAtIndex:[[_swizzle objectAtIndex:i1] intValue]] stream];
	[[_decoders objectAtIndex:[[_swizzle objectAtIndex:i1] intValue]] setStream:[[_decoders objectAtIndex:[[_swizzle objectAtIndex:i2] intValue]] stream]];
	[[_decoders objectAtIndex:[[_swizzle objectAtIndex:i2] intValue]] setStream:save];
	/*
	id save = [[streams objectAtIndex:i1] stream];
	id swap = [[streams objectAtIndex:i2] stream];
	[_streams replaceObjectAtIndex:i1 withObject:swap];
	[_streams replaceObjectAtIndex:i2 withObject:save];*/
}

- (TTVVideoStream*)streamAtIndex:(int)index {
	return [_streams objectAtIndex:index];
}

- (TTVDecoderThread*)decoder:(int)index { 
	return [_decoders objectAtIndex:index];
}

- (int)streamCount {
	return [_decoders count];
}

- (void)preroll {
//	[_decoders makeObjectsPerformSelector:@selector(preroll)];
}

- (BOOL)play {
//	[_decoders makeObjectsPerformSelector:@selector(play)];
	return YES;
}

- (void)allDone {
	[_decoders makeObjectsPerformSelector:@selector(allDone)];
}

@end


@implementation TTVDeck

- (id)initWithFilenames:(NSArray*)filenames {
	self = [super init];
	if (self != nil) {
		NSMutableArray *streams = [NSMutableArray array];
		for(int i = 0; i < [filenames count]; i++) {
			Class textureClass = (i != 1) ? [VSYUVProgramTexture class] : [VSAlphaProgramTexture class];
			TTVVideoStream *stream = [[[TTVVideoStream alloc] initWithTextureClass:textureClass] autorelease];
			[streams addObject:stream];
		}
		_pictureSource = [[TTVPictureSource alloc] initWithFilenames:filenames streams:streams];
		_renderer = [[TTVRenderer alloc] init];
	}
	return self;
}

- (void)drawOutput:(NSRect)rect context:(NSOpenGLContext*)context {
	[_renderer drawOutput:rect context:context pictureSource:_pictureSource];
}

- (TTVPictureSource*)pictureSource {
	return _pictureSource;
}

- (void)setInputFilenames:(NSArray*)filenames {
	for(int i = 0 ; i < [filenames count]; i++) {
		if (![[[_pictureSource decoder:i] inputFilename] isEqualToString:[filenames objectAtIndex:i]]) {
			[[_pictureSource decoder:i] changeMediaFile:[filenames objectAtIndex:i]];
		}
	}
}

- (void)advance {
	[_pictureSource advance];
}

- (void)preroll {
	[_pictureSource preroll];
}

- (BOOL)play {
	[_pictureSource play];
	return YES;
}

- (void)allDone {
	[_pictureSource allDone];
}

- (int)streamCount {
	return [_pictureSource streamCount];
}

@end

@interface TTVTextField : NSTextField
{
}
@end

@implementation TTVTextField
- (void)keyDown:(NSEvent*)event {
	NSLog(@"%@ , keydown %@", [self class], event);
}
@end

@interface TTVOperation : NSObject
{
	NSDictionary *_params;
}
+ (TTVOperation*)operationWithParams:(NSDictionary*)params;
- (id)initWithParams:(NSDictionary*)params;
- (NSDictionary*)params;
@end

@implementation TTVOperation
+ (TTVOperation*)operationWithParams:(NSDictionary*)params {
	return [[[[self class] alloc] initWithParams:params] autorelease];
}
- (id)initWithParams:(NSDictionary*)params {
	self = [super init];
	if (self != nil) {
		_params = [params retain];
	}
	return self;
}
- (id)copyWithZone:(NSZone *)zone {
	return [[[self class] alloc] initWithParams:[[self params] copy]];
}
- (void) dealloc {
	[_params release];
	_params = (void*)0x9;
	[super dealloc];
}

- (NSDictionary*)params {
	return _params;
}
@end

@implementation TTVTableView
- (BOOL)acceptsFirstResponder {
	return NO;
}
- (BOOL)becomeFirstResponder {
	return [[[self enclosingScrollView] superview] becomeFirstResponder];
}
@end


@implementation TTVCommandView

- (void)loadStuff {
	_scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth([self frame]), NSHeight([self frame])-20)];
	[_scrollView setHasVerticalScroller:YES];
	[_scrollView setBorderType:NSBezelBorder];

	NSRect tableRect = NSMakeRect(0, 0, [_scrollView contentSize].width, [_scrollView contentSize].height);
	_tableView = [[[TTVTableView alloc] initWithFrame:tableRect] autorelease];
	NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:@"glar"] autorelease];
	[[column headerCell] setStringValue:@""];
	[_tableView addTableColumn:column];
	[column setWidth:NSWidth([self frame])];
	[_tableView setDelegate:self];
	[_tableView setDataSource:self];

	[_scrollView setDocumentView:_tableView];

	float height = NSHeight([self frame]) - NSHeight([_scrollView frame]);
	_textfield = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, NSHeight([self frame])-height, NSWidth([self frame]), height)] autorelease];
	[_textfield setDelegate:self];
	[self addSubview:_scrollView];
	[self addSubview:_textfield];
	[_tableView reloadData];
}

- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect]) != nil) {
		NSLog(@"command view rect %@", NSStringFromRect(frameRect));
		[self loadStuff];
	}
	return self;
}

- (void)setStreamIndex:(int)index {
	_streamIndex = index;
}
- (int)streamIndex { return _streamIndex; }

- (BOOL)becomeFirstResponder {
	NSLog(@"bfajlkfjdslfjalksfjlksf");
	return [_textfield becomeFirstResponder];
}

- (void)setHighlighted:(BOOL)hilighted {
	if (hilighted) {
		[_tableView setHighlightedTableColumn:[[_tableView tableColumns] objectAtIndex:0]];
	} else {
		[_tableView setHighlightedTableColumn:nil];
	}
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command {
	if (command == @selector(complete:)) {
		return YES;
	}
	NSLog(@"do command!!!! control %@, selector %@", control, NSStringFromSelector(command));
	if ([self respondsToSelector:command]) {
		[self performSelector:command withObject:control];
		return YES;
	}
	return NO;
}

- (void)setDelegate:(id)delegate {
	_delegate = delegate;
	[self match:@""];
    [_tableView reloadData];
}
- (id)delegate { return _delegate; }

- (void)executeSelectedRow {
	int row = [self selectedRow];
	if (row != -1) {
		[[self delegate] commandView:self executeRow:row];
	}
}

- (int)selectedRow {
	return [_tableView selectedRow];
}

- (void)setSelectedRow:(int)row {
	if (row < [[_tableView dataSource] numberOfRowsInTableView:_tableView]) {
		[_tableView selectRow:row byExtendingSelection:NO];
		[_tableView scrollRowToVisible:row];
//		[self executeSelectedRow];
	}
}

- (NSString*)matchForSelectedRow {
	return [self matchForRow:[self selectedRow]];
}

- (void)moveLeft:(id)sender {
	[[self delegate] commandView:self moveLeft:sender];
}

- (void)moveRight:(id)sender {
	[[self delegate] commandView:self moveRight:sender];
}

- (void)moveDown:(id)sender {
	[self setSelectedRow:[_tableView selectedRow]+1];
}

- (void)moveUp:(id)sender {
	[self setSelectedRow:[_tableView selectedRow]-1];
}

- (void)insertNewline:(id)sender {
	[[[NSApplication sharedApplication] delegate] setMode:nil];
	int row = [_tableView selectedRow];
	if (row != -1) {
//		[[[_commands objectAtIndex:0] operationAtIndex:row] execute];
//		NSString *path = [[[VSFileLibrary library] libraryPath] stringByAppendingPathComponent:[[_commands objectAtIndex:0] operationAtIndex:row]];
//		[[[[[[TTVAppDelegate shared] decks] objectAtIndex:1] pictureSource] decoder:0] changeInputFilename:path];
	}
}

- (void)cancelOperation:(id)sender {
	[_textfield setStringValue:@""];
	[self controlTextDidChange:nil];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	[self executeSelectedRow];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [_matches count];
}

- (NSArray*)match:(NSString*)string {
	[_matches release];
	_matches = [[[self delegate] commandView:self match:string] retain];
	return _matches;
}

- (void)controlTextDidChange:(NSNotification*)notification {
	NSString *string = [[notification object] stringValue];
	if (string == nil) {
		string = @"";
	}
	[self match:string];
    [_tableView reloadData];
	int row = [_tableView selectedRow];
	if (row == -1 && [_matches count] > 0) {
		[self setSelectedRow:0];
	} else {
		[self executeSelectedRow];
	}
}

- (NSString*)matchForRow:(int)row {
	if (row >=0 && row < [_matches count]) {
		return [_matches objectAtIndex:row];
	}
	return nil;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	return [_matches objectAtIndex:rowIndex];
}

- (void)drawRect:(NSRect)rect {
    [[NSColor redColor] set];
	NSRectFill(rect);
}
@end

extern int __fullScreenIsMainScreen;

@implementation TTVAppDelegate

- (BOOL)isFullscreen {
	return [[VSOpenGLContext fullscreenContext] isFullscreen];
}

- (BOOL)handleEvent:(NSEvent*)event {
	BOOL handled = NO;
	if (event != nil && ([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) != 0) {
//		return NO;
	}
	NSLog(@"event %@", event);	
	if(event != nil && ([event type] == NSKeyDown) && ([event keyCode] == 0x32)) {	
		[self toggleDeck:nil];
		handled = YES;
	}
	else if (event != nil && ([event type] == NSKeyDown) && ([event keyCode] == 0x35)) {
		[self setMode:nil];
		handled = YES;
	}
//	else if (event != nil && ([event type] == NSKeyDown) && ([event keyCode] == 0x3)) {
//		//[self toggleFullscreen:nil];
//		handled = YES;
//	}	
	else if (event != nil && ([event type] == NSKeyDown) && ([event keyCode] == 0x30)) {
		//[self activateNextCommandView:_mode!=nil];
		[self activateNextCommandView:YES];
		handled = YES;
	}	
	else if (event != nil && ([event type] == NSKeyDown) && ([[event characters] isEqualToString:@" "])) {
		[self togglePause:self];
		handled = YES;
	}
	else if (event != nil && ([event type] == NSKeyDown) && [self mode] == nil && ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[[event characters] characterAtIndex:0]])) {
		[[[_modeMap objectForKey:@"'"] objectForKey:@"modeObject"] handleEvent:event];
		handled = YES;
	}
	else {
		if (event != nil && ([event type] == NSKeyDown)	 ) {
			NSLog(@"keycode is 0x%X", [event keyCode]);
		}
		if (event != nil && ([event type] == NSKeyDown) && _mode == nil) {
			NSString *chars = [event characters];
			if (chars != nil) {
				NSDictionary *d = [_modeMap objectForKey:chars];
				if (d != nil) {
					[self setMode:[d objectForKey:@"modeObject"]];
					handled = YES;
				}
			}

		}
		else {
			handled = [[self mode] handleEvent:event];
		}
	}
	NSLog(@"handled %d", handled);
	return handled;
}

- (void)setMode:(id)mode {
	[_mode leaveMode];
	_mode = mode;
	
	NSString *name = [mode displayName];
	if (name == nil) {
		name = @"Command:";
	}
	NSLog(@"setting mode: %@", name);
	[_modeTextfield setStringValue:name];
	
	[_mode enterMode];
	if (_mode == nil) {
		[[_controlsView	window] makeFirstResponder:nil];
		[[self activeCommandView] cancelOperation:nil];
	}
}

- (id)mode {
	return _mode;
}

- (void)keyDown:(NSEvent*)event {
	NSLog(@"key down %@", event);
}

- (void)activateCommandView:(BOOL)setFirstResponder {
	NSView *view = [_commandViews objectAtIndex:_commandViewIndex];
	[((NSCell*)view) setHighlighted:YES];
	if (setFirstResponder) {
		[[view window] makeFirstResponder:view];
	}
}

- (void)activateNextCommandView:(BOOL)setFirstResponder {
	NSView *view = [_commandViews objectAtIndex:_commandViewIndex];
	[((NSCell*)view) setHighlighted:NO];
	_commandViewIndex = (_commandViewIndex+1)%3;
	[self activateCommandView:setFirstResponder];
}

- (TTVCommandView*)activeCommandView {
	return [_commandViews objectAtIndex:_commandViewIndex];
}

- (NSArray*)commandView:(TTVCommandView*)view match:(NSString*)string {
	return [[self mode] match:string];
}
- (void)commandView:(TTVCommandView*)view executeRow:(int)row {
	[[self mode] executeRow:row];
//	int index = [view streamIndex];
//	NSString *path = [[VSFileLibrary library] pathForFilename:[view matchForRow:row]];
//	TTVDeck *deck = [self previewDeck];
//	[[[deck pictureSource] decoder:index%3] changeInputFilename:path];
}

- (void)commandView:(TTVCommandView*)view moveLeft:(id)sender {
	[[self mode] moveLeft];
}

- (void)commandView:(TTVCommandView*)view moveRight:(id)sender {
	[[self mode] moveRight];
}

- (NSArray*)decks {
	return _decks;
}

- (TTVDeck*)previewDeck {
	int previewDeckIndex = (_outputDeckIndex+1)%2;
	if (_affectOutput) {
		return [self outputDeck];
	}
	return [_decks objectAtIndex:previewDeckIndex];
}

- (TTVDeck*)outputDeck {
	return [_decks objectAtIndex:_outputDeckIndex];
}

- (void)drawPreview:(NSRect)iRect viewRect:(NSRect)vrect context:(NSOpenGLContext*)context deck:(TTVDeck*)deck
{
	//NSLog(@"thread 0x%X, context 0x%X, before drawPreview", (int)[NSThread currentThread], (int)[NSOpenGLContext currentContext]);
	CGLContextObj cgl_ctx = [context CGLContextObj];
	double ar = 16.0/9.0;
	double previewOffset = 0.3*NSHeight(vrect);
	double outputHeight = (NSHeight(vrect)-previewOffset);
	double outputWidth = outputHeight*ar;
	NSRect outputRect = NSInsetRect(NSMakeRect(vrect.origin.x, 0, outputWidth, outputHeight), 10, 10);
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluOrtho2D(0, vrect.size.width, 0, vrect.size.height);
	ttv_check_gl_error();
	
	/* this is essential, it uploads the textures from the PBO */
	[deck drawOutput:outputRect context:context];
	
	double previewWidth = NSWidth(vrect)/6 - 10;
	double previewHeight = previewWidth/ar;
	//double previewGap = 10;
	NSRect previewRect = NSMakeRect(vrect.origin.x, NSHeight(vrect)-previewHeight, previewWidth, 200);

	for(int i = 0; i < 3; i++) {
		[[[deck pictureSource] streamAtIndex:i] previewInRect:previewRect context:[context CGLContextObj]];
		previewRect.origin.x += previewWidth+10;
	}

	for(int i = 0 ; 0 && i < [_timings count]; i++) {
		NSRect xrect = NSMakeRect(1250, 400, 20, 250);
//		NSRect xrect = NSMakeRect(outputRect.size.width, 400, 200, 250);
		[[_timings objectAtIndex:i] drawInRect:xrect context:[context CGLContextObj]];
		glTranslatef(0, 4, 0);
	}
	
	//NSLog(@"thread 0x%X, context 0x%X, after drawPreview", (int)[NSThread currentThread], (int)[NSOpenGLContext currentContext]);
}

- (void)togglePause:(id)sender {
	_paused = !_paused;
}

- (void)toggleOutputActive:(id)sender {
	_affectOutput = !_affectOutput;
}

- (void)advance {
	if (_initialized != YES) {
		return;
	}
//	NSLog(@"advancing!!");
#if 1
	static int counter = 0;
	static NSTimeInterval last60 = 0.0;
	
	if (counter % 60 == 0) {
//		NSLog(@"rendered 60, %g fps", 60.0/([NSDate timeIntervalSinceReferenceDate] - last60));
		last60 = [NSDate timeIntervalSinceReferenceDate];
	}
	counter++;
#endif	

	NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];	

	if (!_paused) {
		start = [NSDate timeIntervalSinceReferenceDate];	
		[_decks makeObjectsPerformSelector:@selector(advance)];

		double ar = 4/3;
		
		if ([self isFullscreen]) {
			[[[VSOpenGLContext fullscreenContext] openGLContext] makeCurrentContext];
			NSRect vrect = [[[NSScreen screens] objectAtIndex:0] frame];
			if (!__fullScreenIsMainScreen) {
				vrect = [[[NSScreen screens] objectAtIndex:1] frame];
			}
			CGLContextObj cgl_ctx = [[[VSOpenGLContext fullscreenContext] openGLContext] CGLContextObj];
			glClearColor(0.0, 0.0, 0.0, 1.0);
			glClear(GL_COLOR_BUFFER_BIT);
			
			glMatrixMode(GL_PROJECTION);
			glLoadIdentity();
			gluOrtho2D(0, vrect.size.width, 0, vrect.size.height);
			[[_decks objectAtIndex:_outputDeckIndex] drawOutput:NSMakeRect(0, 0, vrect.size.width/1, vrect.size.height/1) context:[[VSOpenGLContext fullscreenContext] openGLContext]];
			[[[VSOpenGLContext fullscreenContext] openGLContext] flushBuffer];
		}
		if (!__fullScreenIsMainScreen || __fullScreenIsMainScreen  != [self isFullscreen]) {
			[[_controlsView openGLContext] makeCurrentContext];
			CGLContextObj cgl_ctx = [[_controlsView openGLContext] CGLContextObj];
			glClearColor(0.0, 0.0, 0.0, 1.0);
			glClear(GL_COLOR_BUFFER_BIT);
			NSRect r = [_controlsView frame];
//			r.origin.x = -r.size.width/4;
			r.origin.x = -10;
//			r.size.width /= 2;
			[self drawPreview:NSMakeRect(-1*ar/2, -1, 2, 2) viewRect:r context:[_controlsView openGLContext] deck:[self previewDeck]];
			r.origin.x += 30+r.size.width/2;
			[self drawPreview:NSMakeRect(-1*ar/2, -1, 2, 2) viewRect:r context:[_controlsView openGLContext] deck:[self outputDeck]];
			[[_controlsView openGLContext] flushBuffer];
		}		
	}

	if (!_timings) {
		_timings = [[NSMutableArray array] retain];
		[_timings addObject:[[[TTVTimerStrip alloc] initWithSampleCount:200] autorelease]];
		[_timings addObject:[[[TTVTimerStrip alloc] initWithSampleCount:200] autorelease]];		
	}

	[[_timings objectAtIndex:0] tick:[NSDate timeIntervalSinceReferenceDate] - start];
	start = [NSDate timeIntervalSinceReferenceDate];

	[[_timings objectAtIndex:1] tick:[NSDate timeIntervalSinceReferenceDate] - start];
	
}



- (void)enterFullscreen {
	
//	CGDirectDisplayID displayID = [self displayIDForOutputWindow];

	if (CGDisplayCapture([[VSOpenGLContext fullscreenContext] displayID]) == kCGErrorSuccess) {
//	if (CGDisplayCapture(kCGDirectMainDisplay) == kCGErrorSuccess) {
//		CGDisplayHideCursor(kCGDirectMainDisplay);
		//_screenSize.width = CGDisplayPixelsWide(kCGDirectMainDisplay);
		//_screenSize.height = CGDisplayPixelsHigh(kCGDirectMainDisplay);
		NSLog(@"setting fullscreen on %d", [[VSOpenGLContext fullscreenContext] displayID]);
//		_activeContexts = _fullscreenContexts;
		[[VSOpenGLContext fullscreenContext] enterFullscreen];
//		[[[VSOpenGLContext fullscreenContext] openGLContext] makeCurrentContext];
	}
}

- (void)exitFullscreen {
	[TTVTextureSource lockGL];
	CGReleaseAllDisplays();
	[[VSOpenGLContext fullscreenContext] exitFullscreen];
	[TTVTextureSource unlockGL];
}


- (void)renderThread
{

	int frame = 0;
	NSTimeInterval frameDuration = 1.0/60.0;
	NSTimeInterval error = 1.0/100.0;
	NSTimeInterval sleepDuration = 1.0/200.0;
	NSTimeInterval nextDeadline = [NSDate timeIntervalSinceReferenceDate] + frameDuration;
	int HZ = 2000000000;
	set_realtime(HZ/60, HZ/3300, HZ/2200);

 	for(;;) {
		BOOL exit = NO;	
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#if 1
		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		if (now >= nextDeadline) {
			if (now > nextDeadline + error) {
//				NSLog(@"dropped frame %d, %f seconds late", frame, now - nextDeadline);
			}
			nextDeadline = [NSDate timeIntervalSinceReferenceDate] + frameDuration;
			frame++;
			[TTVTextureSource lockGL];
//			[[VSOpenGLContext fullscreenContext] flushBuffer];
			[self advance];
			exit = _exitRenderThread;
			[TTVTextureSource unlockGL];
//			NSLog(@"frame %d, %f seconds late", frame, now - nextDeadline);
		}

#endif

		/* [NSDate dateWithTimeIntervalSinceNow:] appears to leak a CFDateRef with CFDateCreate  */
		NSDate *next = (NSDate*)CFDateCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+sleepDuration);
		[NSThread sleepUntilDate:next];
		CFRelease((CFDateRef)next);

		[pool release];
		if (exit) {
			[NSThread exit];
			break;
		}
	}

}

- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)needsPanelToBecomeKey { return NO; }

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSLog(@"we got a note!");
}


- (void)installContext:(NSOpenGLView*)view preview:(BOOL)preview
{
       [view clearGLContext];
       VSOpenGLContext *context = [VSOpenGLContext context];
       [context setPreview:preview];
       [view setOpenGLContext:[context openGLContext]];
}

- (void)addMode:(Class)modeClass forKey:(NSString*)key {
	[_modeMap setValue:[NSDictionary dictionaryWithObjectsAndKeys:
		key, @"keyBinding",
		[[[modeClass alloc] init] autorelease], @"modeObject",
		nil] forKey:key];
}

- (void)awakeFromNib {

/*
	NSScreen *screen = [NSScreen mainScreen];
	NSWindow *window = [_qcView window];
	NSRect frame = [window frameRectForContentRect:[screen frame]];
	frame = NSInsetRect(frame, -20, -20);
	[window setFrame:frame display:YES animate:YES];
	*/	
//	[window setLevel:NSModalPanelWindowLevel];
//	+ (NSRect)frameRectForContentRect:(NSRect)windowContent styleMask:(unsigned int)windowStyle
//	NSLog(@"screens %@", [[[NSScreen screens] objectAtIndex:1] deviceDescription]);

//	CGDisplayRegisterReconfigurationCallback(MyDisplayReconfigurationCallBack, 7 /* void * userInfo */);

	_modeMap = [[NSMutableDictionary alloc] init];
	[self addMode:[TTVLoadMode class] forKey:@"l"];
	[self addMode:[TTVMarkMode class] forKey:@"m"];
	[self addMode:[TTVRestoreMode class] forKey:@"'"];
	[self addMode:[TTVAffectOutputMode class] forKey:@"o"];
	[self addMode:[TTVAdjustMode class] forKey:@"a"];
	[self addMode:[TTVSwapChannelMode class] forKey:@"s"];
	[self addMode:[TTVMatchOutputMode class] forKey:@"t"];
	[self setMode:nil];
	[[_controlsView window] setInitialFirstResponder:[self activeCommandView]];
	
	NSRect windowRect = NSInsetRect([[NSScreen mainScreen] frame], 50, 50);

	/* note! we need to replace the NSOpenGLContext in the view with a context of our own the shares textures wit the fullscreen context */
	[self installContext:_controlsView preview:YES];
	
	[[_controlsView window] setFrame:windowRect display:YES];
	
	float windowHeight = NSHeight([[_controlsView window] frame]);
	// now variable
	float searchViewHeight = windowHeight *0.25;
//	float searchViewWidth = (NSWidth([[_controlsView window] frame]) - NSWidth([_controlsView frame])) / 3 - 15;
	float searchViewWidth = 210;
	_commandViews = [[NSMutableArray alloc] init];


	for(int i = 0; i < 3; i++) {
		TTVCommandView *view = [[TTVCommandView alloc] initWithFrame:NSMakeRect(10+(i)*(10+searchViewWidth), windowHeight-searchViewHeight, searchViewWidth, searchViewHeight-50)];
		[_commandViews addObject:view];
		[view setStreamIndex:i+3];
		[view setDelegate:self];
		[[_controlsView superview] addSubview:view];
	}
	
	NSString *inputs[20];
	for(int i = 0; i < 6; i++) {
		inputs[i] = [[VSFileLibrary library] pathForFilename:@"black2.m2v"];
	}
//	inputs[0] = [[VSFileLibrary library] pathForFilename:@"dark-drive.m2v"];
//	inputs[1] = [[VSFileLibrary library] pathForFilename:@"freezer-002-test.m2v"];
//	inputs[2] = [[VSFileLibrary library] pathForFilename:@"marching_vob_01t_001.m2v"];
//	inputs[3] = [[VSFileLibrary library] pathForFilename:@"ocean-seaweed-forest.m2v"];
//	inputs[4] = [[VSFileLibrary library] pathForFilename:@"sheep-2008.m2v"];
//	inputs[5] = [[VSFileLibrary library] pathForFilename:@"tv-noise-slow.m2v"];
	NSLog(@"inputs %@", inputs[0]);

	NSLog (@"image browser is %@", _imageBrowser);
	NSLog (@" browser datasource is %@", [_imageBrowser dataSource]);

	[[_controlsView window] setInitialFirstResponder:_controlsView];
	
	[_imageBrowser setCellSize:NSMakeSize(100, 100)];

	_decks = [[NSMutableArray array] retain];
	[_decks addObject:[[[TTVDeck alloc] initWithFilenames:[NSArray arrayWithObjects:inputs[0], inputs[1], inputs[2], nil]] autorelease]];
	[_decks addObject:[[[TTVDeck alloc] initWithFilenames:[NSArray arrayWithObjects:inputs[3], inputs[4], inputs[5], nil]] autorelease]];

	
	for(int j = 0; j < [_decks count]; j++) {
		[[_decks objectAtIndex:j] preroll];
	}
	for(int j = 0; j < [_decks count]; j++) {
		[[_decks objectAtIndex:j] play];
	}
	
	NSLog(@"__fullScreenIsMainScreen %X", __fullScreenIsMainScreen);
	if ( __fullScreenIsMainScreen == 0) {
//		CGDirectDisplayID fullscreenDisplayId = [[[[[NSScreen screens] objectAtIndex:([[NSScreen screens] count]-1)] deviceDescription] objectForKey:@"NSScreenNumber"] intValue];
//		CVDisplayLinkCreateWithDisplay(fullscreenDisplayId, &__displayLink);
//		CVDisplayLinkSetOutputCallback(__displayLink, myCVDisplayLinkDisplayCallback, self);
		[[[VSOpenGLContext fullscreenContext] openGLContext] setFullScreen];
//		CVDisplayLinkStart(__displayLink);
//		NSLog(@"display link %X", __displayLink);
	}
	

	[NSThread detachNewThreadSelector:@selector(renderThread) toTarget:self withObject:nil];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	_initialized = YES;
}


- (void)toggleDeck:(id)sender {
	_outputDeckIndex = 	(_outputDeckIndex+1) % 2;
}	

- (void)reloadClipSequence:(id)sender {
	[_imageBrowser setAnimates:NO];	
	[_imageBrowser setDataSource:sender];
	[_imageBrowser reloadData];
	[_imageBrowser setNeedsDisplay:YES];
}


- (void)addImagesFromPath: (NSString *)path
{
    NSArray *       array  = [[NSFileManager defaultManager] directoryContentsAtPath: path];
    NSEnumerator *  enumerator;
    NSString *      imagePath;
    
    enumerator = [array objectEnumerator];
    while (imagePath = [enumerator nextObject])
    {
        if ([[[imagePath pathExtension] lowercaseString] isEqualToString: @"jpg"]) {
			NSString *item_path = [NSString stringWithFormat: @"%@/%@", path, imagePath];
			TTVBrowserItem *item = [[[TTVBrowserItem alloc] initWithPath: item_path] autorelease];
			[_imagePaths addObject: item];
        }
    }
}

- (void)loadImages
{

    // find all images inside the 'Screen Savers'
    if (NULL == _imagePaths)
    {
        _imagePaths = [[NSMutableArray alloc] init];

        NSArray *       array  = [[NSFileManager defaultManager] directoryContentsAtPath: @"/System/Library/Screen Savers/"];
        NSEnumerator *  enumerator;
        NSString *      path;
        
        enumerator = [array objectEnumerator];
        while (path = [enumerator nextObject])
        {
            if ([[path pathExtension] isEqualToString: @"slideSaver"])
            {
                [self addImagesFromPath: [NSString stringWithFormat: @"/System/Library/Screen Savers/%@/Contents/Resources/", path]];
            }
        }
    }
}

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser {
	return [_imagePaths count];;
}

- (id) imageBrowser:(IKImageBrowserView *) itemAtIndex:(NSUInteger)index {
	return [_imagePaths objectAtIndex:index];
}


- (BOOL) imageBrowser:(IKImageBrowserView *) view  moveItemsAtIndexes: (NSIndexSet *)indexes toIndex:(unsigned int)destinationIndex
{
      int index;
      NSMutableArray *temporaryArray;
 
      temporaryArray = [[[NSMutableArray alloc] init] autorelease];
      for(index=[indexes lastIndex]; index != NSNotFound;
                         index = [indexes indexLessThanIndex:index])
      {
          if (index < destinationIndex)
              destinationIndex --;
 
          id obj = [_imagePaths objectAtIndex:index];
          [temporaryArray addObject:obj];
          [_imagePaths removeObjectAtIndex:index];
      }
 
      // Insert at the new destination
      int n = [temporaryArray count];
      for(index=0; index < n; index++){
          [_imagePaths insertObject:[temporaryArray objectAtIndex:index]
                        atIndex:destinationIndex];
      }
 
      return YES;
}

- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)bowser {
//	[[bowser dataSource] setSequenceIndex:[[bowser selectionIndexes] firstIndex]];
}
- (void) imageBrowser:(IKImageBrowserView *)bowser cellWasDoubleClickedAtIndex:(NSUInteger)index {
	[[bowser dataSource] setSequenceIndex:index];
}

- (void)updateSequenceSelection:(NSNumber*)newIndex {
//	[_imageBrowser setSelectionIndexes:[NSIndexSet indexSetWithIndex:[newIndex intValue]] byExtendingSelection:NO];
//	[_imageBrowser setSelectionIndexes:nil byExtendingSelection:NO];
}

- (IBAction)toggleFullscreen:(id)sender {

	if ([self isFullscreen]) {
		[self exitFullscreen];
	}
	else {
		[self enterFullscreen];
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	NSLog(@"will terminate!!");
	[_decks makeObjectsPerformSelector:@selector(allDone)];
	[TTVTextureSource lockGL];
	_exitRenderThread = YES;
	[TTVTextureSource unlockGL];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	[self exitFullscreen];
}

- (void)applicationWillBecomeActive:(NSNotification *)aNotification{
	[[VSFileLibrary library] rescan];
}

@end

/* need to trap this callback so all the textures get updated */
@implementation TTVQCView

- (void)setDelegate:(id)delegate
{
	_delegate = delegate;
}
- (id)delegate
{
	return _delegate;
}



@end

static NSMutableDictionary *_clocks = nil;
static NSMutableArray *_values = nil;
static NSLock *_lock = nil;

@implementation VSClock

+ (void)lock
{
	[_lock lock];
}

+ (void)unlock
{
	[_lock lock];
}

+ (NSMutableDictionary*)clocks
{
	return _clocks;
}

+ (void)initialize
{
	_clocks = [[NSMutableDictionary alloc] init];
	_lock = [[NSRecursiveLock alloc] init];
}

+ (NSDictionary*)fetchAndInsert:(id)obj value:(double)value
{
//	[[self class] lock];
	NSDictionary *prev = [[[self class] clocks] objectForKey:[obj description]];
//	NSTimeInterval delay = [NSDate timeIntervalSinceReferenceDate] - [[prev objectForKey:@"lastUpdate"] timeIntervalSinceReferenceDate];
	NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:obj, @"object", [NSNumber numberWithDouble:value], @"value", nil];
	[[[self class] clocks] setObject:item forKey:[obj description]];
//	[[self class] unlock];
	return prev;
}

+ (void)tick:(id)obj value:(double)value
{
//	NSLog(@"%X tick locking", [NSThread currentThread]);
//	BOOL locked = [_lock tryLock];
//	while(!locked) {
//		locked = [_lock tryLock];
//	}
//	[[self class] lock];
	[[self class] fetchAndInsert:obj value:value];
//	NSLog(@"%X tick unlocking", [NSThread currentThread]);
//	[[self class] unlock];

}

+ (NSArray*)values
{
//	NSLog(@"%X values locking", [NSThread currentThread]);
//	[[self class] lock];
	if (_values == nil) {
		_values = [[NSMutableArray alloc] init];
	}
	if ([_values count] > 500) {
		[_values removeLastObject];
	}
	NSMutableDictionary *d = [[[NSMutableDictionary alloc] initWithDictionary:[self clocks] copyItems:YES] autorelease];
	[_values insertObject:d atIndex:0];
	NSArray *values = [[_values copy] autorelease];
//	NSLog(@"%X values unlocking", [NSThread currentThread]);
//	[[self class] unlock];
	return values;
}

@end

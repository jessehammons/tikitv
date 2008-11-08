#import "TTVMPEGSlicer.h"
#import "avformat.h"
#import "TTVAppDelegate.h"

#import <OpenGL/CGLMacro.h>
#import <OpenGL/gluMacro.h>


@implementation TTVMPEGSlicer

- (void)setStartFrame:(id)sender {
	int startFrame = [sender intValue];
	[_markInTextField setIntValue:startFrame];
	NSLog(@"set start frame %d", startFrame);
	[_decoder setStartFrame:startFrame];
	[[self clips] adjustClip:[_clipsTableView selectedRow] startFrame:startFrame];
}

- (void)setEndFrame:(id)sender {
	int endFrame = [sender intValue];
	[_markOutTextField setIntValue:endFrame];
	[_decoder setEndFrame:endFrame];
	[[self clips] adjustClip:[_clipsTableView selectedRow] endFrame:endFrame];
}

- (void)awakeFromNib {
	[_controlsView clearGLContext];
	VSOpenGLContext *context = [[VSOpenGLContext context] retain];
	
	long							value = 1;	
	[[context openGLContext] setValues:(const GLint *)&value forParameter:NSOpenGLCPSwapInterval];
	
	[_controlsView setOpenGLContext:[context openGLContext]];
	
	[_markInSlider setTarget:self];
	[_markInSlider setAction:@selector(setStartFrame:)];
	[_markOutSlider setTarget:self];
	[_markOutSlider setAction:@selector(setEndFrame:)];

//	TTVInputContext *inputContext = [[[TTVInputContext alloc] initWithFile:@"/selects/tl_subway_ntsc.m2v"] autorelease];
//	TTVInputContext *inputContext = [[[TTVInputContext alloc] initWithFile:@"/selects/clouds-blue.m2v"] autorelease];
//	TTVInputContext *inputContext = [[[TTVInputContext alloc] initWithFile:@"/selects/2001-streamers-looped.m2v"] autorelease];
	TTVInputContext *inputContext = [[[TTVInputContext alloc] initWithFile:@"/selects/earthviews-firsthalf.m2v"] autorelease];
	
	

	_clips = [[TTVClipList alloc] initWithFile:[inputContext clipListFilename]];
	if ([[self clips] clipCount] == 0) {
		[_clips release];
		[inputContext buildIndex];
		_clips = [[TTVClipList alloc] initWithFile:[[[_decoder mediaReader] inputContext] clipListFilename]];
	}


	TTVVideoStream *stream = [[[TTVVideoStream alloc] initWithTextureClass:[VSYUVProgramTexture class]] autorelease];
//	_decoder = [[TTVDecoderThread alloc] initWithFile:@"/selects/tl_subway_ntsc.m2v" stream:stream];	
//	_decoder = [[TTVDecoderThread alloc] initWithFile:@"/selects/clouds-blue.m2v" stream:stream];
//	_decoder = [[TTVDecoderThread alloc] initWithFile:@"/selects/2001-streamers-looped.m2v" stream:stream];	
	_decoder = [[TTVDecoderThread alloc] initWithFile:@"/selects/earthviews-firsthalf.m2v" stream:stream];
	
	
	[_markInSlider setMinValue:0];
	int frameCount = [[[_decoder mediaReader] inputContext] frameCount];
	NSLog(@"framecount %d", frameCount);
	[_markInSlider setMaxValue:frameCount-1];
	[_markOutSlider setMaxValue:frameCount-1];
	
	
	[_clipsTableView selectRow:0 byExtendingSelection:NO];
	
	_initialized = YES;
	[NSThread detachNewThreadSelector:@selector(renderThread) toTarget:self withObject:nil];
}



- (void)advance {
	if (_initialized != YES) {
		return;
	}
//	NSLog(@"advancing!!");

	[[_controlsView openGLContext] makeCurrentContext];
	CGLContextObj cgl_ctx = [[_controlsView openGLContext] CGLContextObj];
	glClearColor(1.0, 0.0, 0.0, 1.0);
	ttv_check_gl_error();	
	glClear(GL_COLOR_BUFFER_BIT);
	ttv_check_gl_error();	

	[_frameNumberTextField setIntValue:[[[_decoder stream] currentTexture] frameNumber]];
	
	glMatrixMode(GL_PROJECTION);
	ttv_check_gl_error();	
	glLoadIdentity();
	ttv_check_gl_error();	
//	gluOrtho2D(0, vrect.size.width, 0, vrect.size.height);
	ttv_check_gl_error();
	[[_decoder stream] advance];
	[[[_decoder stream] currentTexture] uploadTextureInContext:cgl_ctx];
	ttv_check_gl_error();
	[[[_decoder stream] currentTexture] drawInRect:NSMakeRect(-1, -1, 2, 2) context:[[_controlsView openGLContext] CGLContextObj]];
	ttv_check_gl_error();	
	
	[[_controlsView openGLContext] flushBuffer];
	ttv_check_gl_error();
}

- (BOOL)handleEvent:(NSEvent *)event {
	if ([event type] == NSKeyDown) {
		NSString *s = [event characters];
		if ([s characterAtIndex:0] == 32) {
			_paused = !_paused;
		}
		else {
			//NSLog(@"%@", event);
			if ([event modifierFlags] & NSNumericPadKeyMask) {
				[[_frameNumberTextField window] interpretKeyEvents:[NSArray arrayWithObject:event]];
			} else {
				return NO;
			}
		}		
	}
	return NO;
}

- (TTVClipList *)clips {
	return _clips;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	int selected = [_clipsTableView selectedRow];
	if (selected >= 0) {
		int startFrame = [[[self clips] clipAtIndex:selected] startFrame];
		int endFrame = [[[self clips] clipAtIndex:selected] endFrame];
		[_markInSlider setIntValue:startFrame];
		[_markInTextField setIntValue:startFrame];
		[_markOutSlider setIntValue:endFrame];
		[_markOutTextField setIntValue:endFrame];
		[_decoder setStartFrame:startFrame];
		[_decoder setEndFrame:endFrame];
		[[_decoder stream] reset];
	}
}

- (IBAction)addClip:(id)sender {
	int startFrame = [[[self clips] clipAtIndex:[[self clips] clipCount]-1] endFrame];
	int endFrame = [[[_decoder mediaReader] inputContext] frameCount];
	[[self clips] addClip:startFrame endFrame:endFrame];	
	[_clipsTableView reloadData];
	[_clipsTableView selectRow:[[self clips] clipCount]-1 byExtendingSelection:NO];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [[self clips] clipCount];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return [[[self clips] clipAtIndex:rowIndex] name];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	[[self clips] adjustClip:rowIndex rename:anObject];
}

- (void)moveRight:(id)sender {
	if (_paused) {
		[self advance];
	}
}
- (void)renderThread
{
	int frame = 0;
	NSTimeInterval frameDuration = 1.0/60.0;
	NSTimeInterval error = 1.0/100.0;
	NSTimeInterval sleepDuration = 1.0/200.0;
	NSTimeInterval nextDeadline = [NSDate timeIntervalSinceReferenceDate] + frameDuration;

 	for(;;) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#if 1
		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		if (now >= nextDeadline) {
			if (now > nextDeadline + error) {
				NSLog(@"dropped frame %d, %f seconds late", frame, now - nextDeadline);
			}
			nextDeadline = [NSDate timeIntervalSinceReferenceDate] + frameDuration;
			frame++;
			[TTVTextureSource lockGL];
			if (!_paused) {
				[self advance];
			}
			[TTVTextureSource unlockGL];
//			NSLog(@"frame %d, %f seconds late", frame, now - nextDeadline);
		}

#endif
		/* [NSDate dateWithTimeIntervalSinceNow:] appears to leak a CFDateRef with CFDateCreate  */
		NSDate *next = (NSDate*)CFDateCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+sleepDuration);
		[NSThread sleepUntilDate:next];
		CFRelease((CFDateRef)next);

		[pool release];
	}

}



@end

#import "TTVMPEGSlicer.h"
#import "avformat.h"
#import "TTVAppDelegate.h"

#import <OpenGL/CGLMacro.h>
#import <OpenGL/gluMacro.h>


@implementation TTVMPEGSlicer

- (void)nextMode:(id)sender {
	_currentMode++;
	if (_currentMode >= [_modes count]) {
		_currentMode = 0;
	}
	NSString *mode = [_modes objectAtIndex:_currentMode];
	[_modeTextField setStringValue:mode];
	[self performSelector:NSSelectorFromString(mode) withObject:nil];
}

- (void)setStartFrame:(id)sender {
	int startFrame = [sender intValue];
	if (_scrubbing) {
		int s = startFrame - 5;
		if (s < 0) { s = 0; }
		[_decoder setStartFrame:s];
		[_decoder setEndFrame:startFrame+5];
		[_decoder gotoBeginning];
	}
	else {
		[_decoder setStartFrame:startFrame];
	}
}

- (void)setEndFrame:(id)sender {
	int endFrame = [sender intValue];
	[_markOutTextField setIntValue:endFrame];
	[_decoder setEndFrame:endFrame];
}

- (int)frameCount {
	return [[[_decoder mediaReader] inputContext] frameCount];
}

- (void)select:(id)sender {
	[_decoder setStartFrame:0];
	[_decoder setEndFrame:[_markInSlider	maxValue]+1];
}

- (void)loop_around_a:(id)sender {
	int frame = [[[self clips] clipAtIndex:[_clipsTableView selectedRow]] startFrame];
	TTVFrameIndex *index = [[[_decoder mediaReader] inputContext] index];
	TTVFrameIndexEntry *entry = [index closestEntryForFrame:frame];
	int maxFrames = [_markInSlider	maxValue]+1;
	int startFrame = [entry frameNumber];
	if (startFrame < 0) startFrame = 0;
	int endFrame = [[index nextEntry:[index nextEntry:entry]] frameNumber];
	if (endFrame >= maxFrames) endFrame = maxFrames;
	[_decoder setStartFrame:startFrame];
	[_decoder setEndFrame:endFrame];
	[_decoder gotoBeginning];
}
	
- (void)loop_around_b:(id)sender {
	int frame = [[[self clips] clipAtIndex:[_clipsTableView selectedRow]] endFrame];
	TTVFrameIndex *index = [[[_decoder mediaReader] inputContext] index];
	TTVFrameIndexEntry *entry = [index closestEntryForFrame:frame];
	int maxFrames = [_markInSlider	maxValue]+1;
	int startFrame = [[index previousEntry:[index previousEntry:entry]] frameNumber];
	if (startFrame < 0) startFrame = 0;
	int endFrame = [entry frameNumber];
	if (endFrame >= maxFrames) endFrame = maxFrames;
	[_decoder setStartFrame:startFrame];
	[_decoder setEndFrame:endFrame];
	[_decoder gotoEnd];
}

- (void)loop_clip:(id)sender {
	int selected = [_clipsTableView selectedRow];
	if (selected >= 0) {
		int startFrame = [[[self clips] clipAtIndex:selected] startFrame];
		int endFrame = [[[self clips] clipAtIndex:selected] endFrame];
		[_decoder setStartFrame:startFrame];
		[_decoder setEndFrame:endFrame];
	}
}

- (void)awakeFromNib {
	[_controlsView clearGLContext];
	VSOpenGLContext *context = [[VSOpenGLContext context] retain];
	
	long							value = 1;	
	[[context openGLContext] setValues:(const GLint *)&value forParameter:NSOpenGLCPSwapInterval];
	
	[_controlsView setOpenGLContext:[context openGLContext]];
	
	[_markInSlider setTarget:self];
	[_markInSlider setAction:@selector(setStartFrame:)];

//	NSString *filename = @"/selects/tl_subway_ntsc.m2v";
//	NSString *filename = @"/selects/clouds-blue.m2v";
//	NSString *filename = @"/selects/2001-streamers-looped.m2v";
//	NSString *filename = @"/selects/earthviews-firsthalf.m2v";
//	NSString *filename = @"/selects/castles2_test.m2v";
	NSString *filename = @"/selects/blue-spinner.m2v";
//	NSString *filename = @"/selects/repo_man_first_part.m2v";
//	NSString *filename = @"/selects/bc1_2k7_end.m2v";
//	NSString *filename = @"/selects/africa-1.m2v";
//	NSString *filename = @"/selects/light-drive.m2v";
//	NSString *filename = @"/selects/africa-2.m2v";
//	NSString *filename = @"/selects/freezer-002.m2v";
//	NSString *filename = @"/selects/freezer-002-test.m2v";
	
	

	_modes = [[NSArray arrayWithObjects:@"select:", @"loop_around_a:", @"loop_around_b:", @"loop_clip:", nil] retain];
	_currentMode = -1;
	[self nextMode:nil];
	
	TTVInputContext *inputContext = [[[TTVInputContext alloc] initWithFile:filename] autorelease];
	
	_clips = [[TTVClipList alloc] initWithFile:[inputContext clipListFilename]];
	if ([[self clips] clipCount] == 0) {
		[_clips release];
		[inputContext buildIndex];
		_clips = [[TTVClipList alloc] initWithFile:[[[_decoder mediaReader] inputContext] clipListFilename]];
	}


	TTVVideoStream *stream = [[[TTVVideoStream alloc] initWithTextureClass:[VSYUVProgramTexture class] queueSize:2] autorelease];
	_decoder = [[TTVDecoderThread alloc] initWithFile:filename stream:stream];
	
	[_markInSlider setMinValue:0];
	int frameCount = [[[_decoder mediaReader] inputContext] frameCount];
	NSLog(@"framecount %d", frameCount);
	[_markInSlider setMaxValue:frameCount-1];
	[_markInSlider setDelegate:self];
	[[[_decoder mediaReader] inputContext] setSkipAmount:20];
	
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
	if (!_scrubbing) {
		[_markInSlider setIntValue:[[[_decoder stream] currentTexture] frameNumber]];
	}
	
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

- (void)markIn:(int)frame {
	TTVFrameIndex *index = [[[_decoder mediaReader] inputContext] index];	
	TTVFrameIndexEntry *entry = [index closestEntryForFrame:frame];
	int snappedFrame = [entry frameNumber];
	[[self clips] adjustClip:[_clipsTableView selectedRow] startFrame:snappedFrame];
	[_markInTextField setIntValue:snappedFrame];
}

- (void)markOut:(int)frame {
	TTVFrameIndex *index = [[[_decoder mediaReader] inputContext] index];
	TTVFrameIndexEntry *entry = [index closestEntryForFrame:frame];
	int snappedFrame = [[index nextEntry:entry] frameNumber];
	[[self clips] adjustClip:[_clipsTableView selectedRow] endFrame:snappedFrame];
	[_markOutTextField setIntValue:snappedFrame];
}


- (BOOL)handleEvent:(NSEvent *)event {
	
	if ([event type] == NSKeyDown) {
		int frame = [[[_decoder stream] currentTexture] frameNumber];
		NSString *s = [event characters];
		if ([s characterAtIndex:0] == 32) {
			_paused = !_paused;
		}
		else if ([s isEqualToString:@"a"]) {
			[self markIn:frame];
		}
		else if ([s isEqualToString:@"b"]) {
			[self markOut:frame];
		}
		else if ([s isEqualToString:@"m"]) {
			[self nextMode:nil];
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

- (void)startScrub {
	_scrubbing = YES;
}

- (void)endScrub {
	NSLog(@"end scrub");	
	_scrubbing = NO;
//	[_decoder setEndFrame:[[[self clips] clipAtIndex:[_clipsTableView selectedRow]] endFrame]];
	[_decoder setEndFrame:[self frameCount]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	int selected = [_clipsTableView selectedRow];
	if (selected >= 0) {
		int startFrame = [[[self clips] clipAtIndex:selected] startFrame];
		int endFrame = [[[self clips] clipAtIndex:selected] endFrame];
		[_markInSlider setIntValue:startFrame];
		[_markInTextField setIntValue:startFrame];
		[_markOutTextField setIntValue:endFrame];
		[_decoder setStartFrame:startFrame];
		[_decoder setEndFrame:endFrame];
		[_decoder gotoBeginning];
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
	else if (_currentMode == 1 || _currentMode == 2) {
		int clipIndex = [_clipsTableView selectedRow];
		TTVClip *clip = [[self clips] clipAtIndex:clipIndex];
		TTVFrameIndex *index = [[[_decoder mediaReader] inputContext] index];
		if (_currentMode == 1) {
			TTVFrameIndexEntry *entry = [index closestEntryForFrame:[clip startFrame]];
			[self markIn:[[index nextEntry:entry] frameNumber]];
			[self loop_around_a:nil];
		}
		else {
			TTVFrameIndexEntry *entry = [index closestEntryForFrame:[clip endFrame]-1];
			[self markOut:[[index nextEntry:entry] frameNumber]];
			[self loop_around_b:nil];
		}
	}
}
- (void)moveLeft:(id)sender {
	if (_paused) {
		[_decoder skipBackward];
		[[_decoder stream] reset];
		[self advance];
	}
	else if (_currentMode == 1 || _currentMode == 2) {
		int clipIndex = [_clipsTableView selectedRow];
		TTVClip *clip = [[self clips] clipAtIndex:clipIndex];
		TTVFrameIndex *index = [[[_decoder mediaReader] inputContext] index];
		if (_currentMode == 1) {
			TTVFrameIndexEntry *entry = [index closestEntryForFrame:[clip startFrame]];
			[self markIn:[[index previousEntry:entry] frameNumber]];
			[self loop_around_a:nil];			
		}
		else {
			TTVFrameIndexEntry *entry = [index closestEntryForFrame:[clip endFrame]-1];
			[self markOut:[[index previousEntry:entry] frameNumber]];
			[self loop_around_b:nil];
		}	
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

- (IBAction)splitMedia:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setCanSelectHiddenExtension:YES];
	[openPanel setCanChooseDirectories:YES];	
	if([openPanel runModalForDirectory:@"/selects" file:nil] == NSOKButton) {
		TTVFrameIndex *index = [[[_decoder mediaReader] inputContext] index];
		NSString *inputPath = [[[_decoder mediaReader] inputContext] filename];
		NSString *dir_path = [openPanel filename];
		for(int i = 0; i < [[self clips] clipCount]; i++) {
			int blockLength = 4096*10;
			TTVClip *clip = [[self clips] clipAtIndex:i];
			TTVFrameIndexEntry *startEntry = [index closestEntryForFrame:[clip startFrame]];
			TTVFrameIndexEntry *endEntry = [index closestEntryForFrame:[clip endFrame]-1];
			NSAssert(startEntry && endEntry, @"Fail");
			NSString *outputPath = [[dir_path stringByAppendingPathComponent:[clip name]] stringByAppendingPathExtension:@"m2v"];
			[[NSFileManager defaultManager] createFileAtPath:outputPath contents:nil attributes:nil];
			NSLog(@"writing %@", outputPath);
			NSFileHandle *input = [NSFileHandle fileHandleForReadingAtPath:inputPath];
			NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:outputPath];
			NSAssert(input && output, @"Fail2");
			long long offset = [startEntry offset];
			long long endByte = [endEntry offset];
			[input seekToFileOffset:offset];
			while(offset < endByte) {
				NSUInteger length = (endByte - offset) > blockLength ? blockLength : (endByte-offset);
				NSData * data = [input readDataOfLength:length];
				[output writeData:data];
				offset += length;
			}
			[input closeFile];
			[output closeFile];
		}
	}
		
}

@end

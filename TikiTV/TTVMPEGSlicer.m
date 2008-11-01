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
	[[[_deck pictureSource] decoder:0] setStartFrame:[sender intValue]];
	_paused = YES;
	[[[[_deck pictureSource] decoder:0] stream] reset];
	[_deck advance];
}

- (void)setEndFrame:(id)sender {
	int endFrame = [sender intValue];
	[_markOutTextField setIntValue:endFrame];	
	NSLog(@"set end frame %d", endFrame);
	[[[_deck pictureSource] decoder:0] setEndFrame:[sender intValue]];
	
}

- (void)awakeFromNib {
#if 0
	[_controlsView clearGLContext];
	VSOpenGLContext *context = [[VSOpenGLContext context] retain];
	[_controlsView setOpenGLContext:[context openGLContext]];
	
	[_markInSlider setTarget:self];
	[_markInSlider setAction:@selector(setStartFrame:)];
	[_markOutSlider setTarget:self];
	[_markOutSlider setAction:@selector(setEndFrame:)];

	_deck = [[TTVDeck alloc] initWithFilenames:[NSArray arrayWithObjects:@"/Users/jesse/videos/selects/tl_subway_ntsc.m2v", nil]];
	[_deck preroll];
	VSDecoder *decoder = [[_deck pictureSource] decoder:0];
	
	[decoder buildIndex];
	
	[_markInSlider setMinValue:0];
	[_markInSlider setMaxValue:[decoder frameCount]-1];
	
	[decoder _saveIndex];
	[_deck play];
	
	[NSThread detachNewThreadSelector:@selector(renderThread) toTarget:self withObject:nil];
	
	_initialized = YES;
#endif
}

- (void)advance {
	if (_initialized != YES) {
		return;
	}
//	NSLog(@"advancing!!");

	if (!_paused) {
		[_deck advance];
	}

	[[_controlsView openGLContext] makeCurrentContext];
	CGLContextObj cgl_ctx = [[_controlsView openGLContext] CGLContextObj];
	glClearColor(1.0, 0.0, 0.0, 1.0);
	ttv_check_gl_error();	
	glClear(GL_COLOR_BUFFER_BIT);
	ttv_check_gl_error();	
	
	glMatrixMode(GL_PROJECTION);
	ttv_check_gl_error();	
	glLoadIdentity();
	ttv_check_gl_error();	
//	gluOrtho2D(0, vrect.size.width, 0, vrect.size.height);
	ttv_check_gl_error();
	[[[[_deck pictureSource] streamAtIndex:0] currentTexture] uploadTextureInContext:[[_controlsView openGLContext] CGLContextObj]];
	ttv_check_gl_error();
	[[[[_deck pictureSource] streamAtIndex:0] currentTexture] drawInRect:NSMakeRect(-1, -1, 2, 2) context:[[_controlsView openGLContext] CGLContextObj]];
	ttv_check_gl_error();	
	
	[[_controlsView openGLContext] flushBuffer];
	ttv_check_gl_error();	
	
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
			[self advance];
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

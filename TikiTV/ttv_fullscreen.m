//
//  ttv_fullscreen.m
//  TikiTV2
//
//  Created by Jesse Hammons on 6/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ttv_fullscreen.h"
#import "TTVAppDelegate.h"
#import <QTKit/QTKit.h>

#define ttv_check_gl_error() {		\
	int theError = glGetError();	\
	if(theError) {					\
		ttv_print_gl_error(theError);	\
	}	\
}	\

@implementation ttv_fullscreen

@end
id picturesProxy;
			
@interface Data : NSObject
{
	VSBufferQueue *_fullQueue;
}
- (void)entry;
- (NSData*)nextFrame;
@end

@implementation Data
- (id)init {
	self = [super init];
	if (self != nil) {
		_fullQueue = [[VSBufferQueue alloc] init];
	}
	return self;
}
- (NSData*)nextFrame {
	NSData *data = [_fullQueue dequeue];
//	NSLog(@"next frame, count %d", [_fullQueue count]);
	return data;
}
- (void)entry {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSPort *sendPort = [[NSMachBootstrapServer sharedInstance] portForName:@"TikiTV" host:nil];
	NSConnection *connection = [[NSConnection alloc] initWithReceivePort:(NSPort*)[[sendPort class] port] sendPort:sendPort];	
    picturesProxy = [connection rootProxy];
	
	for(;;) {
		NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
		if ([_fullQueue count] < 10) {
			NSData *data = [[picturesProxy pictureForStream:0] retain];
			if (data == nil) {
				NSLog(@"suck nil data!");
				continue;
			}
			[_fullQueue enqueue:data];
		}

		[pool2 release];	
	}
	[pool release];
}
@end



int main_xxx(int argc, char **argv) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[[VSOpenGLContext fullscreenContext] openGLContext] makeCurrentContext];
	[[VSOpenGLContext fullscreenContext] enterFullscreen];

/*
//	CGLContextObj cgl_ctx = [[[VSOpenGLContext fullscreenContext] openGLContext] CGLContextObj];
	for(int i = 0; i < 100; i++) {
		glClearColor(1.0, 0.0, 0.0, 1.0);
		glClear(GL_COLOR_BUFFER_BIT);
		[[[VSOpenGLContext fullscreenContext] openGLContext] flushBuffer];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}
	return 0;
*/
	
	Data *d = [[Data alloc] init];
	[NSThread detachNewThreadSelector:@selector(entry) toTarget:d withObject:nil];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
	
	TTVRenderer *renderer = [[TTVRenderer alloc] initWithTextureSources:[NSArray arrayWithObjects:
						[[TTVTextureSource alloc] initWithDecoder:nil texture:[[VSYUVProgramTexture alloc] initWithContext:NULL]],
						[[TTVTextureSource alloc] initWithDecoder:nil texture:[[VSAlphaProgramTexture alloc] initWithContext:NULL]],
						[[TTVTextureSource alloc] initWithDecoder:nil texture:[[VSYUVProgramTexture alloc] initWithContext:NULL]],
						nil]];
    CGLContextObj cglContext = CGLGetCurrentContext();
	long newSwapInterval = 1;
    CGLSetParameter(cglContext, kCGLCPSwapInterval, &newSwapInterval);


//	NSData *data = [picturesProxy pictureForStream:0];
//	NSLog(@"data is %d bytes", [data length]);
	
//	CGLContextObj cgl_ctx = [[[VSOpenGLContext fullscreenContext] openGLContext] CGLContextObj];

	for(;;) {
		NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
		NSData *data = [d nextFrame];
		if (data == nil) {
			NSLog(@"nill data!");
			continue;
		}
		
		for(int j = 0; j < 1; j++) {
			void *buf_start = (void*)[data bytes];
			AVPicture *picture = (AVPicture*)buf_start;

			void *data_start = buf_start + (sizeof *picture);
			avpicture_fill(picture, data_start, PIX_FMT_YUV420P, 720, 480);
//			NSLog(@"picture is %d, %d, %d", picture->linesize[0], picture->linesize[1], picture->linesize[2]);
//			NSLog(@"picture is 0x%X, data 0x%X", buf_start, data_start);
			[renderer uploadPicture:data forStream:j];
		}


		double ar = 4/3;
		[renderer drawOutput:NSMakeRect(-2*ar/2, -1, 2*ar, 2) context:[[VSOpenGLContext fullscreenContext] openGLContext]];	

//		glClearColor(1.0, 0.0, 0.0, 1.0);
//		glClear(GL_COLOR_BUFFER_BIT);

		
		[[[VSOpenGLContext fullscreenContext] openGLContext] flushBuffer];
//		NSLog(@"after flushbuffer");
//		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
//		NSLog(@"after running run loop");
		[data release];
		[pool2 release];
	}
	
	[pool release];
	return 0;
}

int main_yyy(int argc, char **argv) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[[VSOpenGLContext fullscreenContext] openGLContext] makeCurrentContext];
	[[VSOpenGLContext fullscreenContext] enterFullscreen];


	CGLContextObj cgl_ctx = [[[VSOpenGLContext fullscreenContext] openGLContext] CGLContextObj];
	for(int i = 0; i < 10; i++) {
		glClearColor(1.0, 0.0, 0.0, 1.0);
		ttv_check_gl_error();
		glClear(GL_COLOR_BUFFER_BIT);
		ttv_check_gl_error();
		[[[VSOpenGLContext fullscreenContext] openGLContext] flushBuffer];
//		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}
//	return 0;

	NSPort *sendPort = [[NSMachBootstrapServer sharedInstance] portForName:@"TikiTV" host:nil];
	NSConnection *connection = [[NSConnection alloc] initWithReceivePort:(NSPort*)[[sendPort class] port] sendPort:sendPort];	
    picturesProxy = [connection rootProxy];
	printf("client configured to use %s\n", ([sendPort class] ==  [NSSocketPort self]) ? "sockets" : "Mach ports");

	NSString *inputs[] = {
		@"/Users/jesse/videos/library/ntsc/1vbitest.m2v",
		@"/Users/jesse/videos/library/ntsc/60numbers.m2v",
		@"/Users/jesse/videos/library/ntsc/spot_reworks_vob_01t_013.vob.m2v",
		@"/Users/jesse/videos/library/ntsc/spot_reworks_vob_01t_002.vob.m2v",
		@"/Users/jesse/videos/library/ntsc/spot_reworks_vob_01t_001.vob.m2v",			
		@"/Users/jesse/videos/library/ntsc/60numbers.m2v",

	};
	NSRect outputRect = [[[NSScreen screens] objectAtIndex:0] frame];
	glMatrixMode(GL_PROJECTION);
	ttv_check_gl_error();
	glLoadIdentity();
	ttv_check_gl_error();
//	gluOrtho2D(0, outputRect.size.width, 0, outputRect.size.height);
	ttv_check_gl_error();

	TTVDeck *deck = [[TTVDeck alloc] initWithFilenames:[NSArray arrayWithObjects:inputs[0], inputs[1], inputs[2], nil]];
	[deck preroll];
	[deck play];
	
	int frame = 0;
	NSTimeInterval frameDuration = 1.0/60.0;
	NSTimeInterval error = 1.0/100.0;
	NSTimeInterval sleepDuration = 1.0/200.0;
	NSTimeInterval nextDeadline = [NSDate timeIntervalSinceReferenceDate] + frameDuration;
	int HZ = 2000000000;
	set_realtime(HZ/60, HZ/3300, HZ/2200);
	
	
	
 	for(;;) {
		NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];



#if 1
		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		if (now >= nextDeadline) {
			if (now > nextDeadline + error) {
				NSLog(@"dropped frame %d, %f seconds late", frame, now - nextDeadline);
			}
			nextDeadline = [NSDate timeIntervalSinceReferenceDate] + frameDuration;
			frame++;
			
			[[[VSOpenGLContext fullscreenContext] openGLContext] makeCurrentContext];
			glClearColor(1.0, 0.0, 0.0, 1.0);
			ttv_check_gl_error();
			glClear(GL_COLOR_BUFFER_BIT);
			ttv_check_gl_error();
			glColor3f(0,0,0);
			glRectf(-1, -1, 0.5, 0.5);
			[deck advance];
			[deck drawOutput:NSMakeRect(-1, -1, 2, 2) context:[[VSOpenGLContext fullscreenContext] openGLContext]];
			[[VSOpenGLContext fullscreenContext] flushBuffer];
//			NSLog(@"proxy says %d", [picturesProxy hello]);
//			int x = [picturesProxy hello];
//			[deck setInputFilenames:[picturesProxy fsFilenames]];

		}

#endif
		/* [NSDate dateWithTimeIntervalSinceNow:] appears to leak a CFDateRef with CFDateCreate  */
		NSDate *next = (NSDate*)CFDateCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+sleepDuration);
		[NSThread sleepUntilDate:next];
		CFRelease((CFDateRef)next);		
		
		
		[pool2 release];
	}
	
	[pool release];
	return 0;
}

int main(int argc, char **argv) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;
	QTMovie *movie = [[QTMovie movieWithFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:argv[1] length:strlen(argv[1])] error:&error] retain];


	if (error) {
		NSLog(@"error is %@", error);
		return 0;
	}
	NSLog(@"mvoei is %@", movie);
	NSLog(@"chapters is %@", [movie chapters]);	
	NSArray *chapters = [movie chapters];
	QTTime start;
	QTTime *pstart = nil;
	NSString *name = nil;
	NSString *pname = nil;
	QTMovie *submovie = nil;
	for(int i = 0; i < [chapters count]+1; i++) {
		QTTime qttime;
		if (i < [chapters count]) {
			NSDictionary *d = [chapters objectAtIndex:i];
			name = [d objectForKey:@"QTMovieChapterName"];
			NSLog(@"chapter name: %@", name);
			qttime = [[d objectForKey:@"QTMovieChapterStartTime"] QTTimeValue];
		}
		else {
			qttime = [movie duration];
		}
		NSLog(@"start time is %@", QTStringFromTime(qttime));
		if (pstart) {
			QTTime duration = QTTimeDecrement(qttime, *pstart);
			QTTimeRange range = QTMakeTimeRange(*pstart, duration);
			NSLog(@"range is %@", QTStringFromTimeRange(range));
			error = nil;
			submovie = [movie movieWithTimeRange:range error:&error];
			if (error) {
				NSLog(@"error %@", error);
			}
			NSLog(@"sub movie is %@", submovie);
			NSString *path = [pname stringByAppendingPathExtension:@".mov"];
			path = [[NSString stringWithFormat:@"%02d_", i] stringByAppendingString:path];
			NSLog(@"writing to path %@", path);
			NSLog(@"result %d", [submovie writeToFile:path withAttributes:nil]);
		}
		pstart = &start;
		start = qttime;
		pname = [name retain];
	}
	
	[pool release];
	return 0;
}
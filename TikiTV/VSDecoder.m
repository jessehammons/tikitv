//
//  VSDecoder.m
//  TikiTV
//
//  Created by Jesse Hammons on 11/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "VSDecoder.h"
#import "VSFileLibrary.h"
#import <OpenGL/CGLMacro.h>
#import <OpenGL/gluMacro.h>

#import "TTVAppDelegate.h"
#import "TTVCore.h"

@implementation TTVClipSequence

- (id)initWithPath:(NSString*)path {
	self = [super init];
	if (self != nil) {
		_path = [path retain];
		[self reload];
	}
	return self;
}

- (void)dealloc {
	[_path release]; _path = (void*)0x11;
	[_sequence release]; _sequence = (void*)0x11;
	[super dealloc];
}

- (void)reload {
	if ([_path hasSuffix:@".ttv_seq"]) {
		NSError *error = nil;
		NSString *contents = [NSString stringWithContentsOfFile:_path encoding:NSASCIIStringEncoding error:&error];
		if (contents != nil && error == nil) {
			NSLog(@"reloading SEQUENCE %@", _path);
			[_sequence autorelease];
			_currentIndex = 0;
			NSArray *tmp = [contents componentsSeparatedByString:@"\n"];
			NSMutableArray *newPlaylist = [[NSMutableArray array] retain];
			for(int i = 0; i < [tmp count]; i++) {
				NSString *path = [[VSFileLibrary library] pathForFilename:[tmp objectAtIndex:i]];
				if ([[NSFileManager defaultManager] fileExistsAtPath:path] == YES) {
					[newPlaylist addObject:[tmp objectAtIndex:i]];
				}
			}
			for(int i = 0; i < [newPlaylist count] && i < [_sequence count]; i++) {
				if ([[newPlaylist objectAtIndex:i] isEqualToString:[_sequence objectAtIndex:i]] == NO) {
					_currentIndex = i;
					break;
				}
			}
			_sequence = newPlaylist;
		}
		else {
			NSLog(@"NIL FOR PLIST: %@; error %@", _path, error);
		}
	}

}

- (void)advance {
	if ([_sequence count] == 0 || _sequence == nil) {
		return;
	}
	_currentIndex = (_currentIndex+1) % [_sequence count];
}

- (void)rewind {
	if ([_sequence count] == 0 || _sequence == nil) {
		return;
	}
	_currentIndex = _currentIndex - 1;
	if (_currentIndex < 0) {
		_currentIndex = [_sequence count] - 1;
	}
}

- (NSString*)pathForCurrentClip {
	if ([_sequence count]) {
		return [_sequence objectAtIndex:_currentIndex];
	}
	else {
		return [[VSFileLibrary library] pathForFilename:@"black2.m2v"];
		NSLog(@"EMPTY PLAYLIST?: %@", _path);
	}
}

@end

NSRecursiveLock *_ffmpegLockClass = nil;

@implementation VSDecoder

+ (int)decoderNumber {
	static int n = 1;
	return n++;
}


- (VSDecoder*)initWithInputFilename:(NSString*)filename stream:(TTVVideoStream*)stream
{
	self = [super init];
	if (self != nil) {
		[self setStream:stream];
		_decoderNumber = [[self class] decoderNumber];
		_pauseCondition = [[NSConditionLock alloc] initWithCondition:VS_DECODER_STATE_PAUSED];	
		[self setInputFilename:filename];
		_browserItems = [[NSMutableArray array] retain];
		[self reset];
	}
	return self;
}

- (void) dealloc {
	[_pauseCondition release]; _pauseCondition = nil;
	[self reset];
	[self setInputFilename:nil];
	[super dealloc];
}

- (NSString*)displayName {
	if (_displayName == nil) {
		_displayName = [[@"dec" stringByAppendingFormat:@"%d", _decoderNumber] retain];
	}
	return @"";
}

+ (void)lockFFMPEGClass {
	if (_ffmpegLockClass == nil) {
		_ffmpegLockClass = [[NSRecursiveLock alloc] init];
	}
	[_ffmpegLockClass lock];
}

+ (void)unlockFFMPEGClass {
	[_ffmpegLockClass unlock];
}

- (void)lockFFMPEG {
//	NSLog(@"%X **LOCK", (int)[NSThread currentThread]);
	if (_ffmpegLock == nil) {
		_ffmpegLock = [[NSRecursiveLock alloc] init];
	}
	[_ffmpegLock lock];
}

- (void)unlockFFMPEG
{
//	NSLog(@"%X UNLOCK", (int)[NSThread currentThread]);
	[_ffmpegLock unlock];
}

- (int)openInputFile
{
	AVFormatParameters params, *ap = &params;		
	av_register_all(); /* this only does stuff the first time it's called */
	memset(ap, 0, sizeof(*ap));
	int rv = av_open_input_file(&_ffmpegInputContext, [_inputFilename fileSystemRepresentation], NULL, 0, ap);
	if (rv != 0) {
		NSLog(@"error opening file %@", _inputFilename);
		return rv;
	}
	_ffmpegFrame = avcodec_alloc_frame();
	AVPacket pkt;	
	rv = av_read_frame(_ffmpegInputContext, &pkt);
//	rv = 0;
	if (rv != 0) {	
		NSLog(@"error reading frame %@", _inputFilename);
		av_close_input_file(_ffmpegInputContext);
		_ffmpegInputContext = NULL;
		_ffmpegStream = NULL;
	}
	else {
		av_free_packet(&pkt);
	}
	return rv;
}

- (int)openCodec
{
	_ffmpegStream = _ffmpegInputContext->streams[0];
	AVCodec *codec = avcodec_find_decoder(_ffmpegStream->codec->codec_id);
	_ffmpegStream->codec->flags2 |= CODEC_FLAG2_FAST;
//	_ffmpegStream->codec->hurry_up = 5;
	_ffmpegStream->codec->debug |= FF_DEBUG_PICT_INFO;
	int rv = avcodec_open(_ffmpegStream->codec, codec);
		if (rv != 0) {
		NSLog(@"error opening codec %@", _inputFilename);
	}
	return rv;
}


- (void)decodeFirst
{
	AVPacket pkt;
	int got_frame = 0;
	int rv = 0;
	int try = 0, tries = 1000;	
	while (rv == 0 && got_frame == 0 && try < tries) {
		rv = av_read_frame(_ffmpegInputContext, &pkt);
		if (rv == 0) {
			avcodec_decode_video(_ffmpegStream->codec, _ffmpegFrame, &got_frame, pkt.data, pkt.size);
//			NSLog(@"preroll, rv is %d, got_frame %d, size %d", rv, got_frame, pkt.size);
		}
		try++;
	}
	if (got_frame) {
		_state = VS_DECODER_STATE_DECODING;
		[[NSNotificationCenter defaultCenter] postNotificationName:VSDecoderDidPreRoll object:self];
	}
	else {
		[self reset];
	}
	av_free_packet(&pkt);
//	av_seek_frame(_ffmpegInputContext, -1, AV_TIME_BASE*200, 0);
}

- (void)_advanceSequence {
	int newIndex = _playlistIndex == ([_playlist count]-1) ? 0 : _playlistIndex+1;
	[self setSequenceIndex:newIndex];
	[[[NSApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(updateSequenceSelection:) withObject:[NSNumber numberWithInt:_playlistIndex] waitUntilDone:NO];
}

- (void)advanceSequence {
	if (_playlist != nil) {
		[self _advanceSequence];
	}
	else {
	}
}

- (void)rewindSequence {
	int newIndex = _playlistIndex ? _playlistIndex-1 : [_playlist count]-1;
	[self setSequenceIndex:newIndex];
	[[[NSApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(updateSequenceSelection:) withObject:[NSNumber numberWithInt:_playlistIndex] waitUntilDone:NO];
}

- (void)setSequenceIndex:(int)index {
	if ([_playlist count] == 0 || _playlist == nil || index < 0 || index >= [_playlist count]) { return; }
	_playlistIndex = index;
	[self setInputFilename:[[VSFileLibrary library] pathForFilename:[_playlist objectAtIndex:_playlistIndex]]];
	_do_reset = YES;
	NSLog(@"input filename is %d, %@", _playlistIndex, _inputFilename);
}

- (void)reloadSequence {
	if ([_playlistPath hasSuffix:@".ttv_seq"]) {
		NSError *error = nil;
		NSString *contents = [NSString stringWithContentsOfFile:_inputFilename encoding:NSASCIIStringEncoding error:&error];
		if (contents != nil && error == nil) {
			NSLog(@"REOPENING SEQUENCE %@", _inputFilename);
			[_playlist autorelease];
			[_browserItems removeAllObjects];
			_playlistIndex = 0;
			NSArray *tmp = [contents componentsSeparatedByString:@"\n"];
			NSMutableArray *newPlaylist = [[NSMutableArray array] retain];
			for(int i = 0; i < [tmp count]; i++) {
				NSString *path = [[VSFileLibrary library] pathForFilename:[tmp objectAtIndex:i]];
				if ([[NSFileManager defaultManager] fileExistsAtPath:path] == YES) {
					[newPlaylist addObject:[tmp objectAtIndex:i]];
					[_browserItems addObject:[[[TTVBrowserItem alloc] initWithPath:path] autorelease]];
				}
			}
			for(int i = 0; i < [newPlaylist count] && i < [_playlist count]; i++) {
				if ([[newPlaylist objectAtIndex:i] isEqualToString:[_playlist objectAtIndex:i]] == NO) {
					_playlistIndex = i;
				}
			}
			_playlist = newPlaylist;
			if ([_playlist count]) {
				[self setInputFilename:[[VSFileLibrary library] pathForFilename:[_playlist objectAtIndex:_playlistIndex]]];
				_do_reset = YES;
			}
			else {
				[self setInputFilename:[[VSFileLibrary library] pathForFilename:@"black2.m2v"]];
				NSLog(@"EMPTY PLAYLIST?: %@", _inputFilename);
			}
			[[[NSApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(reloadClipSequence:) withObject:self waitUntilDone:NO];
		}
		else {
			NSLog(@"NIL FOR PLIST: %@; error %@", _inputFilename, error);
		}
	}
}

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser {
	return [_browserItems count];
}

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index {
	return [_browserItems objectAtIndex:index];
}


- (BOOL)imageBrowser:(IKImageBrowserView *)view  moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(unsigned int)destinationIndex {
	int index;
	NSMutableArray *temporaryArray = [[[NSMutableArray alloc] init] autorelease];
	for(index=[indexes lastIndex]; index != NSNotFound; index = [indexes indexLessThanIndex:index]) {
		if (index < destinationIndex) {
			destinationIndex --;
		}
		id obj = [_browserItems objectAtIndex:index];
		[temporaryArray addObject:obj];
		[_browserItems removeObjectAtIndex:index];
	}

	// Insert at the new destination
	int n = [temporaryArray count];
	for(index=0; index < n; index++) {
		[_browserItems insertObject:[temporaryArray objectAtIndex:index] atIndex:destinationIndex];
	}
	[_playlist removeAllObjects];
	for(int i = 0; i < [_browserItems count]; i++) {
		NSString *path = [[_browserItems objectAtIndex:i] path];
		[_playlist addObject:[path stringByReplacingOccurrencesOfString:[[VSFileLibrary library] libraryPath] withString:@""]];
	}
	[self setSequenceIndex:destinationIndex];
	return YES;
}

- (void)preroll
{
//	NSLog(@"%X preroll!!", (int)self);
	int rv = 0;
	
	/*********/	
	[[self class] lockFFMPEGClass];

	if (_ffmpegInputContext == NULL) {
		_state = VS_DECODER_STATE_PREROLLING;
		if ([_playlistPath hasSuffix:@".ttv_seq"] && _playlist == nil) {
			[self reloadSequence];
		}
		rv = [self openInputFile];
		if (rv == 0) {
			rv = [self openCodec];
		}
		if (rv == 0) {
//			[self decodeFirst];
			_state = VS_DECODER_STATE_DECODING;
		}
	}
	
	[[self class] unlockFFMPEGClass];
	/*#######*/
//	NSLog(@"preroll is %d", rv);
		
	if (rv != 0) {
		[self reset];
	}
}

- (void)_decodeLoop
{
	AVPacket pkt;
	int counts[10];

	NSLog(@"%X decode thread starting", (unsigned)[NSThread currentThread]);	
		
	for(;;) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		int got_frame = 0;
		int rv = 0;		
//		return;

//	NSLog(@"%X decode thread before condition lcock", (unsigned)[NSThread currentThread]);	
	
		[_pauseCondition lockWhenCondition:VS_DECODER_STATE_DECODING];
		[_pauseCondition unlockWithCondition:VS_DECODER_STATE_DECODING];
		
//	NSLog(@"%X decode thread after condition lcock", (unsigned)[NSThread currentThread]);	
		
		if ([self state] != VS_DECODER_STATE_DECODING) {
			goto loopEnd;
		}
		
//	NSLog(@"%X decode thread after state lcock", (unsigned)[NSThread currentThread]);	

		NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
		[self lockFFMPEG];			/*****************************************************************************************************************************************/	
		
		if (_allDone) {
			[NSThread exit];
			goto unlockEnd;
		}
		if (_ffmpegInputContext != NULL) {
			got_frame = 0;

			rv = av_read_frame(_ffmpegInputContext, &pkt);
			
			if (_startFrame || _endFrame || _extentChanged) {
				if (_currentFrameIndex < _startFrame || (_endFrame > 0 && _currentFrameIndex > _endFrame) || (_endFrame == 0 && rv != 0) || _extentChanged) {
					AVIndexEntry *entry = _ffmpegInputContext->streams[0]->index_entries + _startFrame;
					if (_extentChanged) {
						//AVIndexEntry *entry = _ffmpegInputContext->streams[0]->index_entries + _extentChanged;	
					}
					av_seek_frame(_ffmpegInputContext, 0, entry->timestamp, 0);
					NSLog(@"seeking to %qd", entry->timestamp);
					rv = av_read_frame(_ffmpegInputContext, &pkt);
					_currentFrameIndex = _startFrame;
				}
				_extentChanged = 0;
			} else {
				if (_do_reset) {
					[self reset];
					[self preroll];
					_do_reset = NO;
					if (_ffmpegInputContext) {
						rv = av_read_frame(_ffmpegInputContext, &pkt);
					}
					else {
						rv = -1;
					}
				}
				else if (rv < 0) {
					if (_playlist != nil) {
						[self _advanceSequence];
//						[self reset];
//						[self preroll];
						[self unlockFFMPEG];		/*############################################################################################################################################*/
						continue;
//						rv = av_read_frame(_ffmpegInputContext, &pkt);
					}
					else {
						url_fseek(_ffmpegInputContext->pb, 0, SEEK_SET);
						NSLog(@"reloading %@, I %d, P %d, B %d!!", _inputFilename, counts[1], counts[2], counts[3]);
						counts[0] = counts[1] = counts[2] = counts[3] = 0;
						rv = av_read_frame(_ffmpegInputContext, &pkt);
					}
				}
			}
			
//		NSLog(@"%X decode thread after read frame, %d", (unsigned)[NSThread currentThread], rv);



			if (rv == 0) {
				/* seems to be a small memory leak when decoding?? */
				//NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

				avcodec_decode_video(_ffmpegStream->codec, _ffmpegFrame, &got_frame, pkt.data, pkt.size);
				
				/* frame type info i-frame, p-frame, b-frame */
				if (_ffmpegStream->codec->max_b_frames >= 0 && _ffmpegStream->codec->max_b_frames < 5) {
					counts[_ffmpegStream->codec->max_b_frames]++;
				}
///				[VSClock tick:[NSString stringWithFormat:@"%X", (int)[NSThread currentThread]] value:[NSDate timeIntervalSinceReferenceDate] - start];
				//NSLog(@"decode rv is %d, got_frame %d, size %d", rv, got_frame, pkt.size);
			}
		}
		
		if (!_textureID) {
			_context = [[VSOpenGLContext context] retain];
			[[_context openGLContext] makeCurrentContext];
			NSLog(@"thread 0x%X, context 0x%X", (int)[NSThread currentThread], (int)[NSOpenGLContext currentContext]);
			CGLContextObj cgl_ctx = [[_context openGLContext] CGLContextObj];
			glGenTextures(1, (GLuint*)&_textureID);
		}

		NSTimeInterval decodeTime = [NSDate timeIntervalSinceReferenceDate] - start;
		if (_ffmpegInputContext != NULL && got_frame) {
			NSSize size = NSMakeSize(_ffmpegInputContext->streams[0]->codec->width, _ffmpegInputContext->streams[0]->codec->height);
//			NSLog(@"thread 0x%X, filling buffer for decoded size %@, linesize %d", (int)[NSThread currentThread], NSStringFromSize(size), _ffmpegFrame->linesize[0]);
//			NSLog(@"thread 0x%X, context 0x%X", (int)[NSThread currentThread], (int)[NSOpenGLContext currentContext]);			
			[_stream fillBuffer:(AVPicture*)_ffmpegFrame size:size decodeTime:decodeTime context:[[_context openGLContext] CGLContextObj]];
			//NSLog(@"thread 0x%X, context 0x%X, AFTER filling buffer for decoded size %@, linesize %d", (int)[NSThread currentThread], (int)[NSOpenGLContext currentContext], NSStringFromSize(size), _ffmpegFrame->linesize[0]);
			_currentFrameIndex++;
		}
unlockEnd:
		[self unlockFFMPEG];		/*############################################################################################################################################*/				
		

		
		[self lockFFMPEG];		/*############################################################################################################################################*/				
		[self unlockFFMPEG];		/*############################################################################################################################################*/				

		if (rv != 0) {
			[_pauseCondition unlockWithCondition:VS_DECODER_STATE_PAUSED];
		}
//		[VSClock tick:self forFrame:frames];
loopEnd:
		[pool release];
		
	}
	NSLog(@"decode thread exiting");
	av_free_packet(&pkt);
}

- (BOOL)play
{
	NSLog(@"%X play!!", (int)[NSThread currentThread]);
	
	/*********/	
	[self lockFFMPEG];

	if (_state == VS_DECODER_STATE_DECODING) {
		if (_detached == 0) {
			_detached = 1;
			NSLog(@"%X play, detaching thread", (int)[NSThread currentThread]);			
			[NSThread detachNewThreadSelector:@selector(_decodeLoop) toTarget:self withObject:nil];
		}		
	}
	
	[self unlockFFMPEG];
	/*#######*/

	if ([_pauseCondition tryLockWhenCondition:VS_DECODER_STATE_PAUSED]) {
		_state = VS_DECODER_STATE_DECODING;
		[_pauseCondition unlockWithCondition:VS_DECODER_STATE_DECODING];
	}
	return YES;
}

- (void)pause
{
	NSLog(@"%X pause!!", (int)[NSThread currentThread]);
	if ([_pauseCondition tryLockWhenCondition:VS_DECODER_STATE_DECODING]) {
		_state = VS_DECODER_STATE_PAUSED;
		[_pauseCondition unlockWithCondition:VS_DECODER_STATE_PAUSED];
	}
}

- (void)setStream:(TTVVideoStream*)stream {
	if (stream != _stream) {
		[_stream release];
		_stream = [stream retain];
	}
}

- (TTVVideoStream*)stream {
	return _stream;
}

- (void)reset
{
	
	[[self class] lockFFMPEGClass];			/*****************************************************************************************************************************************/	

	memset(&_ffmpegUVUYPicture, 0x11, sizeof(_ffmpegUVUYPicture));
	
	if (_ffmpegFrame != NULL) {	
		av_freep(&_ffmpegFrame);
		_ffmpegFrame = NULL;
	}
	if (_ffmpegStream != NULL) {
		/* we have to close the codecs, but av_close_input_file refers to the codecs! */
		avcodec_close(_ffmpegStream->codec);
//		_ffmpegStream->codec = (void*)(0xafc);
//		_ffmpegStream = (void*)(0xafc);
	}		
	
	
	if (_ffmpegInputContext != NULL) {
		av_close_input_file(_ffmpegInputContext);
		_ffmpegInputContext = NULL;
		_ffmpegStream = NULL;
	}

	[_stream reset];

	_state = VS_DECODER_STATE_INIT;
		
	[[self class] unlockFFMPEGClass];		/*############################################################################################################################################*/
	

}

- (void)buildIndex
{
	_ffmpegInputContext->max_index_size = 1024*1024*4*sizeof(AVIndexEntry);
	AVPacket pkt;	
	int rv = av_read_frame(_ffmpegInputContext, &pkt);
	while(rv >= 0) {
		_frameCount++;
		rv = av_read_frame(_ffmpegInputContext, &pkt);
	}
	NSLog(@"index entries is %d", _ffmpegInputContext->streams[0]->nb_index_entries);
}

- (void)_saveIndex {
	NSMutableArray *entries = [NSMutableArray array];
	for(int i = 0; i < _ffmpegInputContext->streams[0]->nb_index_entries; i++) {
		AVIndexEntry *e = _ffmpegInputContext->streams[0]->index_entries + i;
		NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithLongLong: e->pos],		@"pos",
			[NSNumber numberWithLongLong: e->timestamp],@"timestamp",
			[NSNumber numberWithInt:e->flags],			@"flags",
			[NSNumber numberWithInt:e->size],			@"size",
			[NSNumber numberWithInt:e->min_distance],	@"min_distance",
			nil];
		[entries addObject:entry];
	}
	[[NSPropertyListSerialization dataFromPropertyList:entries format:NSPropertyListBinaryFormat_v1_0 errorDescription:nil] writeToFile:_index_name atomically:YES];


	NSLog(@"entries %@", entries);
}


- (void)changeInputFilename:(NSString*)filename
{
	NSLog(@"CHANGE TO %@", filename);
	//(gdb) p ((URLContext*)_ffmpegInputContext->pb->opaque)->priv_data

	[self lockFFMPEG];
	[_playlist release];
	[_playlistPath release];
	_playlistPath = nil;
	_playlist = nil;
	_playlistIndex = 0;
	
	if ([filename hasSuffix:@".ttv_seq"]) {
		_playlistPath = [filename retain];
	}
	
//	[self reset];
	_do_reset = YES;
	[self setInputFilename:filename];
//	[self preroll];

//	url_fclose(_ffmpegInputContext->pb);
//	url_fopen(_ffmpegInputContext->pb, [filename fileSystemRepresentation], URL_RDONLY);	
//	avcodec_close(_ffmpegStream->codec);
//	AVCodec *codec = avcodec_find_decoder(_ffmpegStream->codec->codec_id);
//	_ffmpegStream->codec->flags2 |= CODEC_FLAG2_FAST;
//	int rv = avcodec_open(_ffmpegStream->codec, codec);

	[self unlockFFMPEG];	
}

- (void)setInputFilename:(NSString*)filename
{
	if (_inputFilename != filename) {
		[_index_name release];
//		_index_name = [[[filename stringByDeletingLastPathComponent] stringByAppendingPathComponent:[[filename lastPathComponent] stringByAppendingPathExtension:@"ttvindex"]] retain];
		[_inputFilename release];
		_inputFilename = [filename retain];
	}
}

- (NSString*)inputFilename
{
	if (_playlist != nil) {
		return _playlistPath;
	}
	return _inputFilename;
}

- (void)setState:(int)state
{
	NSLog(@"%X setState!!", (int)[NSThread currentThread]);
	
	/*********/	
	[self lockFFMPEG];
	
	_state = state;
	
	[self unlockFFMPEG];
	/*#######*/
}

- (int)state
{
//	NSLog(@"%X state!!", (int)[NSThread currentThread]);
	int rstate = 0;
	/*********/	
	[self lockFFMPEG];
	
	rstate = _state;
	
	[self unlockFFMPEG];
	/*#######*/
	
	return rstate;
}

- (AVFrame*)ffmpegFrame
{
	return _ffmpegFrame;
}



- (void)setEndFrame:(int)frame{
	_endFrame = frame;
	_extentChanged = frame;
}

- (void)setStartFrame:(int)frame{
	_startFrame = frame;
	_extentChanged = frame;
}
- (int)startFrame { return _startFrame; }
- (int)endFrame { return _endFrame; }
- (int)frameCount { return _frameCount; }



- (NSSize)sizeNoLock
{
	return NSMakeSize(_ffmpegStream->codec->width, _ffmpegStream->codec->height);
}

- (NSSize)size
{
	[self lockFFMPEG];			/*****************************************************************************************************************************************/	
	
	NSSize size =  [self sizeNoLock];
	
	[self unlockFFMPEG];		/*############################################################################################################################################*/
	
	return size;
}

- (void)allDone {
	[self lockFFMPEG];			/*****************************************************************************************************************************************/	
	_allDone = YES;
	[self unlockFFMPEG];		/*############################################################################################################################################*/	
}

@end

NSString *VSDecoderDidPreRoll = @"VSDecoderDidPreRoll";
NSString *VSDecoderDidDecodeFrame = @"VSDecoderDidDecodeFrame";

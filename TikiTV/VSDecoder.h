//
//  VSDecoder.h
//  TikiTV
//
//  Created by Jesse Hammons on 11/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Accelerate/Accelerate.h>


#import "VSPipe.h"
#import "avformat.h"
#import <OpenGL/gl.h>

@class TTVVideoStream;
@class VSOpenGLContext;


enum {
	VS_DECODER_STATE_INIT,
	VS_DECODER_STATE_PREROLLING,
	VS_DECODER_STATE_PREROLLED,
	VS_DECODER_STATE_DECODING,
	VS_DECODER_STATE_PAUSED
};

@class VSTexture;

@interface VSDecoder : NSObject {
	NSString *_inputFilename;
	int _decoderNumber;
	NSString *_displayName;
	int _state;
	AVFormatContext *_ffmpegInputContext;
	AVFrame *_ffmpegFrame;
	AVPicture _ffmpegUVUYPicture;
	AVStream *_ffmpegStream;
	BOOL _allDone;
	
	int _detached;
	NSConditionLock *_pauseCondition;
	
	NSLock *_ffmpegLock;
	
	int _currentFrameIndex;

	int _frameCount;
	NSString *_index_name;
	int _startFrame;
	int _endFrame;
	int _extentChanged;
	
	TTVVideoStream * _stream;
	VSOpenGLContext *_context;
	int _textureID;
	BOOL _do_reset;
	NSString *_playlistPath;
	NSMutableArray *_playlist;
	int _playlistIndex;
	NSMutableArray *_browserItems;
}

//+ (VSDecoder*)decoderWithInputFilename:(NSString*)filename;
- (VSDecoder*)initWithInputFilename:(NSString*)filename stream:(TTVVideoStream*)stream;
- (void)preroll;
- (BOOL)play;
- (void)pause;
- (void)reset;

- (void)buildIndex;

- (void)setInputFilename:(NSString*)filename;
- (NSString*)inputFilename;

- (void)allDone;

- (void)setState:(int)state;
- (int)state;

- (NSSize)size; 
- (NSSize)sizeNoLock;
- (AVFrame*)ffmpegFrame;
- (void)setStream:(TTVVideoStream*)stream;
- (TTVVideoStream*)stream;

- (void)changeInputFilename:(NSString*)filename;
- (void)advanceSequence;
- (void)rewindSequence;
- (void)setSequenceIndex:(int)index;

- (int)frameCount;
- (void)setStartFrame:(int)frame;
- (int)startFrame;
- (void)setEndFrame:(int)frame;
- (int)endFrame;

@end

NSString *VSDecoderDidPreRoll;
NSString *VSDecoderDidDecodeFrame;

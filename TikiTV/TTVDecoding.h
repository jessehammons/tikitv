//
//  TTVDecoding.h
//  TikiTV2
//
//  Created by Jesse Hammons on 8/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

#import "TTVCore.h"
#import "VSPipe.h"
#import "avformat.h"

@class TTVPictureSource;

#define ttv_check_gl_error() {		\
int theError = glGetError();	\
if(theError) {					\
ttv_print_gl_error(theError);	\
}	\
}	\

/* for breakpoints */
void ttv_print_gl_error(int error);

@interface TTVBrowserItem : NSObject
{
	NSString *_path;
}
- (NSString*)path;
- initWithPath:(NSString*)path;
@end

@interface TTVClipSequence : NSObject
{
	NSString *_path;
	NSArray *_sequence;
	int _currentIndex;
}

- (id)initWithPath:(NSString*)path;
- (void)reload;
- (void)advance;
- (void)rewind;
- (NSString*)pathForCurrentClip;

@end

@interface VSClock : NSObject
{
}

+ (void)tick:(id)obj value:(double)value;
+ (NSArray*)values;
+ (NSMutableDictionary*)clocks;

@end


@interface VSTextureUnitTexture : NSObject
{
	GLuint		_textureID;
	const char *_textureName; //this corresponds to the GLSL variable name we are binding this texture to
	GLenum		_textureUnit;
	GLint		_textureUnitIndex;
	
	NSSize		_cachedSize;
	int _cachedRowBytes;
	void *_base;
	int _baseRowBytes;
	GLuint _pbo;
}

- (id)initWithTextureUnit:(GLenum)unit textureUnitIndex:(GLint)unitIndex name:(GLcharARB*)name base:(void*)base rowBytes:(int)rowBytes;
- (void)uploadPlane:(void*)data size:(NSSize)size rowBytes:(GLint)rowBytes program:(GLhandleARB)program context:(CGLContextObj)cgl_ctx;
- (GLuint)textureID;
- (void)bindInContext:(CGLContextObj)cgl_ctx;

@end

#if 0
@interface VSMemoryTextureUnitTexture : NSObject
{
	void *_base;
}
- (id)initWithTextureUnit:(GLenum)unit textureUnitIndex:(GLint)unitIndex name:(GLcharARB*)name;
@end
#endif

@interface TTVTimerStrip : NSObject
{
	int *_samples;
	int _sampleCount;
	int _sampleSize;
	int _listBase;
}
- (id)initWithSampleCount:(int)count;
- (void)tick:(NSTimeInterval)time;
- (void)drawInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx;
@end

@interface VSAbstractProgramTexture : NSObject
{
	GLhandleARB _programHandle;
	
	CGLContextObj	_cgl_ctx;
	NSSize		_cachedSize;
	GLuint		_dl;
	NSData *_data;
	NSTimeInterval _decodeTime;
	int _drawCount;
	BOOL _invalid;
	int _frameNumber;
}
- (id)initWithProgramText:(GLcharARB*)text context:(CGLContextObj)cgl_ctx;
- (void)uploadPicture:(AVPicture*)picture size:(NSSize)size decodeTime:(NSTimeInterval)time frameNumber:(int)frameNumber context:(CGLContextObj)cgl_ctx;
- (void)uploadTextureInContext:(CGLContextObj)cgl_ctx;
- (void)drawInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx;
- (void)previewInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx;
- (NSData*)data;
- (NSTimeInterval)decodeTime;
- (void)recordDroppedFrame;
- (int)frameNumber;
- (BOOL)invalid;
- (void)invalidate;
- (void)setAdjustments:(float*)adjust context:(CGLContextObj)cgl_ctx;

@end

@interface TTVVideoStream : NSObject
{
	NSMutableArray *_buffers;
	VSBufferQueue *_freeBuffers;
	VSBufferQueue *_decodedBuffers;
	//	NSData *__current_frame;
	VSAbstractProgramTexture *__current_frame;
	TTVTimerStrip *_timer;
	float _adjust[4];
}

- (id)initWithTextureClass:(Class)textureClass queueSize:(int)queueSize;
- (id)initWithTextureClass:(Class)textureClass;
- (void)fillBuffer:(AVPicture*)decodedPicture size:(NSSize)size decodeTime:(NSTimeInterval)time frameNumber:(int)frameNumber context:(CGLContextObj)cgl_ctx;
- (void)advance;
- (void)reset;
- (void)previewInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx;
- (VSAbstractProgramTexture*)currentTexture;
- (void)decrementField:(NSString*)field;
- (void)incrementField:(NSString*)field;

@end


@interface VSYUVProgramTexture : VSAbstractProgramTexture
{
	NSArray *_textures;
}
- (id)initWithContext:(CGLContextObj)cgl_ctx;
- (void)uploadPicture:(AVPicture*)picture size:(NSSize)size decodeTime:(NSTimeInterval)time frameNumber:(int)frameNumber context:(CGLContextObj)cgl_ctx;
- (void)drawInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx;
@end


@interface VSAlphaProgramTexture : VSAbstractProgramTexture
{
	VSTextureUnitTexture *_texture;
}
- (id)initWithContext:(CGLContextObj)cgl_ctx;
- (void)uploadPicture:(AVPicture*)picture size:(NSSize)size decodeTime:(NSTimeInterval)time frameNumber:(int)frameNumber context:(CGLContextObj)cgl_ctx;
- (void)drawInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx;
- (void)previewInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx;
@end

@interface VSOpenGLContext : NSObject
{
	NSOpenGLPixelFormat *_pixelFormat;
	NSOpenGLContext *_context;
	QCRenderer *_renderer;
	BOOL _isPreview;
	BOOL _isFullscreen;
}

+ (VSOpenGLContext*)fullscreenContext;
+ (VSOpenGLContext*)context;

- (BOOL)isFullscreen;

- (void)enterFullscreen;
- (void)exitFullscreen;

- (id)initWithAttributes:(NSOpenGLPixelFormatAttribute*)attributes shareContext:(VSOpenGLContext*)share;

- (NSOpenGLPixelFormat*)pixelFormat;
- (NSOpenGLContext*)openGLContext;
- (QCRenderer*)renderer;

- (void)setPreview:(BOOL)preview;
- (BOOL)isPreview;
//- (NSSize)size;

@end


@interface TTVTextureSource : NSObject
{
}

+(void)lockGL;
+(void)unlockGL;

@end


@interface TTVQCView : QCView
{
	id _delegate;
}

- (void)setDelegate:(id)delegate;
- (id)delegate;

@end




@interface TTVRenderer : NSObject
{
}
- (void)drawOutput:(NSRect)rect context:(NSOpenGLContext*)context pictureSource:(TTVPictureSource*)pictureSource;

@end

@interface TTVFrameIndexEntry : NSObject
{
	long long _offset;
	int _length;
	int _frameNumber;
	int _frameType;
}
- (id)initWithOffset:(long long )offset length:(int)length frameNumber:(int)frameNumber frameType:(int)frameType;
- (id)initWithDictionary:(NSDictionary*)d;
- (long long)offset;
- (int)length;
- (int)frameNumber;
- (int)frameType;
- (id)plistify;
@end

@interface TTVFrameIndex : NSObject
{
	NSString *_filename;
	NSMutableArray *_entries;
}

- (id)initWithFile:(NSString*)file;
- (NSString*)filename;
- (int)frameCount;
- (void)addEntry:(TTVFrameIndexEntry*)entry;
- (void)save;
- (TTVFrameIndexEntry*)closestEntryForFrame:(int)frame;
- (long long)byteOffsetForFrame:(int)frame;

@end

@interface TTVClip : NSObject
{
	int _startFrame;
	int _endFrame;
	NSString *_name;
}
- (id)initWithStartFrame:(int)startFrame endFrame:(int)endFrame;
- (id)initWithDictionary:(NSDictionary*)d;
- (int)startFrame;
- (void)setStartFrame:(int)frame;
- (int)endFrame;
- (void)setEndFrame:(int)frame;
- (void)setName:(NSString*)name;
- (NSString*)name;
- (id)plistify;
@end

@interface TTVClipList : NSObject
{
	NSString *_filename;
	NSMutableArray *_clips;
}
- (id)initWithFile:(NSString*)filename;
- (NSString*)filename;
- (int)clipCount;
- (TTVClip*)clipAtIndex:(int)clipIndex;
- (void)addClip:(int)startFrame endFrame:(int)endFrame;
- (void)adjustClip:(int)clipIndex startFrame:(int)startFrame;
- (void)adjustClip:(int)clipIndex endFrame:(int)endFrame;
- (void)adjustClip:(int)clipIndex rename:(NSString*)name;
- (void)save;
@end

@interface TTVPacket : NSObject
{
	/* ... from avformat.h ...
	 * The returned packet is valid
	 * until the next av_read_frame() or until av_close_input_file() and
	 * must be freed with av_free_packet. For video, the packet contains
	 */ 
	AVPacket _pkt;
}

- (AVPacket*)packetPtr;
- (void *)dataPtr;
- (int)dataSize;

@end

@interface TTVInputContext : NSObject
{
	AVFormatContext *_ffmpegContext;
	AVFrame *_ffmpegFrame;
	BOOL _codecOpened;
	NSLock *_ffmpegLock;
	int _frameCount;
	int _currentFrameIndex;
	int _skipAmount;
	TTVFrameIndex *_index;
	int _startFrame;
	int _endFrame;
}
- (id)initWithFile:(NSString*)path;
- (int)currentFrame;
- (void)seekToFrame:(int)frame;
- (void)gotoBeginning;
- (void)setSkipAmount:(int)amt;
- (void)skipForward;
- (void)skipBackward;
- (TTVPacket*)readNextFrame;
- (AVFrame*)decodeFrame:(TTVPacket*)packet;
- (void)buildIndex;
- (NSString*)indexFilename;
- (NSString*)clipListFilename;
- (int)frameCount;
- (TTVFrameIndex*)index;
- (void)setStartFrame:(int)frame;
- (void)setEndFrame:(int)frame;
- (void)setExtents:(TTVClip*)clip;
@end

@interface TTVMediaReader : NSObject
{
	NSString *_filePath;
	TTVInputContext *_inputContext;
}
+ (TTVMediaReader*)mediaReaderForFile:(NSString*)path;
- (id)initWithFile:(NSString*)path;
- (NSString*)filePath;
- (void)skipForward;
- (void)skipBackward;
- (TTVPacket*)readNextFrame;
- (AVFrame*)decodeNextFrame;
- (TTVInputContext *)inputContext;
- (NSSize)currentSize;
@end

@interface TTVFileReader : TTVMediaReader
{
}
- (id)initWithFile:(NSString*)path;
- (void)skipForward;
- (void)skipBackward;
- (TTVPacket*)readNextFrame;

@end

@interface TTVSequenceReader : TTVMediaReader
{
	TTVFileReader *_reader;
	NSMutableArray *_sequence;	
	int _sequenceIndex;
}
- (id)initWithFile:(NSString*)path;
- (NSString*)_currentFile;
- (void)_openCurrentFile;
- (void)skipForward;
- (void)skipBackward;
- (AVFrame*)decodeNextFrame;
@end

@interface TTVClipListReader : TTVMediaReader
{
	TTVClipList *_clips;
	int _currentClipIndex;
}
- (id)initWithFile:(NSString*)path;
- (NSString*)mediaFilename;
- (TTVClipList*)clips;
- (int)currentClipIndex;
- (TTVClip*)currentClip;
- (void)skipForward;
- (void)skipBackward;

@end


/*
 delegate:
 
 [_stream fillBuffer:(AVPicture*)_ffmpegFrame size:size decodeTime:decodeTime context:[[_context openGLContext] CGLContextObj]];
 
 [delegate processPicture:(AVPicture*) properties:(NSDictionary*)properties]
 @"size" - NSSize
 @"decodeTime" - # seconds to read and decode
 
 runs in it's own thread, relies on the delegate to block in process picture
 
 */

@interface TTVDecoderThread : NSObject
{
	TTVMediaReader *_reader;
	TTVVideoStream	*_stream;
	VSBufferQueue *_commandQueue;
	NSRecursiveLock *_lock;
	VSOpenGLContext *_context;
	BOOL _allDone;
}
- (id)initWithFile:(NSString*)path stream:(TTVVideoStream*)stream;
- (void)changeMediaFile:(NSString*)path;
- (void)setStream:(TTVVideoStream*)stream;
- (TTVMediaReader*)mediaReader;
- (TTVVideoStream*)stream;
- (NSString*)inputFilename;
- (void)skipForward;
- (void)skipBackward;
- (void)setStartFrame:(int)startFrame;
- (void)setEndFrame:(int)endFrame;
- (void)allDone;

@end

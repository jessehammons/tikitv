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
	BOOL _invalid;
}
- (id)initWithProgramText:(GLcharARB*)text context:(CGLContextObj)cgl_ctx;
- (void)uploadPicture:(AVPicture*)picture size:(NSSize)size decodeTime:(NSTimeInterval)time context:(CGLContextObj)cgl_ctx;
- (void)uploadTextureInContext:(CGLContextObj)cgl_ctx;
- (void)drawInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx;
- (void)previewInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx;
- (NSData*)data;
- (NSTimeInterval)decodeTime;
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

- (id)initWithTextureClass:(Class)textureClass;
- (void)fillBuffer:(AVPicture*)decodedPicture size:(NSSize)size decodeTime:(NSTimeInterval)time context:(CGLContextObj)cgl_ctx;
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
- (void)uploadPicture:(AVPicture*)picture size:(NSSize)size decodeTime:(NSTimeInterval)time context:(CGLContextObj)cgl_ctx;
- (void)drawInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx;
@end


@interface VSAlphaProgramTexture : VSAbstractProgramTexture
{
	VSTextureUnitTexture *_texture;
}
- (id)initWithContext:(CGLContextObj)cgl_ctx;
- (void)uploadPicture:(AVPicture*)picture size:(NSSize)size decodeTime:(NSTimeInterval)time context:(CGLContextObj)cgl_ctx;
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

@interface TTVMediaTOCEntry : NSObject
{
	int offset;
	int length;
	int frameNumber;
	int frameType;
}
- (id)initWithOffset:(int)offset length:(int)length frameNumber:(int)frameNumber frameType:(int)frameType;
- (int)offset;
- (int)length;
- (int)frameNumber;
- (int)frameType;
@end

@interface TTVInputContext : NSObject
{
	AVFormatContext *_ffmpegContext;
	AVFrame *_ffmpegFrame;
	BOOL _codecOpened;
	NSLock *_ffmpegLock;
}
- (id)initWithFile:(NSString*)path;
- (void)seekToOffset:(int)offset;
- (void)gotoBeginning;
- (void)skipForward;
- (void)skipBackward;
- (TTVPacket*)readNextFrame;
- (AVFrame*)decodeFrame:(TTVPacket*)packet;
@end

@interface TTVMediaTOC : NSObject
{
	NSMutableArray *_entries;
}
- (id)initWithData:(NSData*)data;
- (void)buildTOCFromContext:(TTVInputContext*)inputContext;
- (NSData*)serialize;

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
- (void)skipForward;
- (void)skipBackward;
- (AVFrame*)decodeNextFrame;
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
- (void)allDone;

@end

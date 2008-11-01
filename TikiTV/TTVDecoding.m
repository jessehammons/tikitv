//
//  TTVDecoding.m
//  TikiTV2
//
//  Created by Jesse Hammons on 8/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TTVDecoding.h"
#import "VSFileLibrary.h"


#import <OpenGL/CGLMacro.h>
#import <OpenGL/gluMacro.h>

#import "TTVAppDelegate.h"

void ttv_print_gl_error(int error)
{
	NSLog(@"thread 0x%X, context 0x%X, TTV OpenGL (error 0x%04X): %s", (int)[NSThread currentThread], (int)[NSOpenGLContext currentContext], error, gluErrorString(error));
	//	int *x = (int*)0x5;
	//	*x = 7;
}

#define ttv_check_gl_error() {		\
int theError = glGetError();	\
if(theError) {					\
ttv_print_gl_error(theError);	\
}	\
}	\


//CVReturn myCVDisplayLinkDisplayCallback (CVDisplayLinkRef displayLink, const CVTimeStamp *syncTimeStamp, CVOptionFlags flagsIn, void *displayLinkContext)
//{
//	id ad = [TTVAppDelegate shared];
//	CVReturn error = [ad displayFrame:syncTimeStamp];
//	return error;
//}


@interface TTVScreenChooser : NSObject
{
	NSDictionary *_activeScreens;
}
@end

#if 0
void MyDisplayReconfigurationCallBack(CGDirectDisplayID display,  CGDisplayChangeSummaryFlags flags, void *userInfo)
{
	NSDictionary *dictionary = (NSDictionary*)IODisplayCreateInfoDictionary(CGDisplayIOServicePort(display), 0x0);
	
    if (flags & kCGDisplayBeginConfigurationFlag) {
		NSLog(@"display change! display %X BEGIN, info %X", display, userInfo);
    }
	
    if (flags & kCGDisplayAddFlag) {
		NSLog(@"display change! display %X ADDED, info %X", display, userInfo);
		
		//	NSLog(@"NAME IS %@", dictionary);
		//	NSLog(@"NAME IS %@", [dictionary objectForKey:@"DisplayProductName"]);
		//	NSLog(@"NAME IS %@", [[dictionary objectForKey:CFSTR(kDisplayProductName)] objectForKey:[[NSLocale currentLocale] localeIdentifier]]);
		//CFBundleCopyPreferredLocalizationsFromArray
    }
    else if (flags & kCGDisplayRemoveFlag) {
		NSLog(@"display change! display %X REMOVED, info %X", display, userInfo);
    } else {
		NSLog(@"display change! display %X, flags %X, info %X", display, flags, userInfo);
	}
	if ( (flags & kCGDisplayBeginConfigurationFlag) == 1) {
		NSDictionary *named = [dictionary objectForKey:CFSTR(kDisplayProductName)];
		if (named != nil) {
			NSDictionary *names = [named objectForKey:[[NSLocale currentLocale] localeIdentifier]];
			if (names != nil) {
				NSLog(@"NAME IS %@", names);
			}
		}
	}
	NSLog(@" IS MAIN SCREEN: %d", [[[[[NSScreen screens] objectAtIndex:0] deviceDescription] objectForKey:@"NSScreenNumber"] intValue] == display);
	for(int i = 0; i < [[NSScreen screens] count]; i++) {
		NSLog(@"screesns device id %@", [[[[NSScreen screens] objectAtIndex:i] deviceDescription] objectForKey:@"NSScreenNumber"]);
	}
	
	/*
	 [[NSNotificationCenter defaultCenter]  postNotificationName:TTVDisplayAddedNotification object:nil userInfo:nil];
	 [NSDictionary dictionaryWithObjectsAndKeys:
	 [NSNumber numberWithUnsignedInt:display], @"displayID",
	 name, @"displayProductName",
	 nil]];
	 [[NSNotificationCenter defaultCenter]  postNotificationName:TTVDisplayRemovedNotification object:nil userInfo:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	 [NSNumber numberWithUnsignedInt:display], @"displayID",
	 name, @"displayProductName",
	 nil]];*/
	
}
#endif
#if 0
void MyDisplayReconfigurationCallBack(CGDirectDisplayID display,  CGDisplayChangeSummaryFlags flags, void *userInfo)
{
	
	NSDictionary *dictionary = (NSDictionary*)IODisplayCreateInfoDictionary(CGDisplayIOServicePort(display), 0x0);
	
    if ((flags & kCGDisplayBeginConfigurationFlag) == 0) {
		if (display != [[[[[NSScreen screens] objectAtIndex:0] deviceDescription] objectForKey:@"NSScreenNumber"] intValue])
			if (flags & kCGDisplayAddFlag) {
				[TTVAppDelegate releaseTextures];
				[VSOpenGLContext setFullscreenDisplayId:display];
				[TTVAppDelegate reallocateTextures];
			} else if (flags & kCGDisplayRemoveFlag) {
				[VSOpenGLContext setFullscreenDisplayID:[[[[[NSScreen screens] objectAtIndex:0] deviceDescription] objectForKey:@"NSScreenNumber"] intValue]]
			}
		NSLog(@"display change! display %X REMOVED, info %X", display, userInfo);
    } else {
		NSLog(@"display change! display %X, flags %X, info %X", display, flags, userInfo);
	}
	if ( (flags & kCGDisplayBeginConfigurationFlag) == 1) {
		NSDictionary *named = [dictionary objectForKey:CFSTR(kDisplayProductName)];
		if (named != nil) {
			NSDictionary *names = [named objectForKey:[[NSLocale currentLocale] localeIdentifier]];
			if (names != nil) {
				NSLog(@"NAME IS %@", names);
			}
		}
	}
	NSLog(@" IS MAIN SCREEN: %d", [[[[[NSScreen screens] objectAtIndex:0] deviceDescription] objectForKey:@"NSScreenNumber"] intValue] == display);
	for(int i = 0; i < [[NSScreen screens] count]; i++) {
		NSLog(@"screesns device id %@", [[[[NSScreen screens] objectAtIndex:i] deviceDescription] objectForKey:@"NSScreenNumber"]);
	}
}
#endif

int __fullScreenIsMainScreen = 1;

@implementation VSOpenGLContext

+ (VSOpenGLContext*)fullscreenContext
{
	
	//	for(int i = 0; i < [[NSScreen screens] count]; i++) {
	//			NSLog(@"screesns device id %@", [[[[NSScreen screens] objectAtIndex:i] deviceDescription] objectForKey:@"NSScreenNumber"]);
	//	}
	
	//	
	CGDirectDisplayID fullscreenDisplayId = (CGDirectDisplayID)[[[[[NSScreen screens] objectAtIndex:([[NSScreen screens] count]-1)] deviceDescription] objectForKey:@"NSScreenNumber"] intValue];
	if ([[NSScreen screens] count] > 1) {
		__fullScreenIsMainScreen = 0;
	}
	
	//NSLog(@"name is %@", [[NSProcessInfo processInfo] processName]);
	static VSOpenGLContext *fullscreenContext = nil;
	if (fullscreenContext == nil) {
		//		CGDirectDisplayID reallyFSDisplayID = [[[NSProcessInfo processInfo] processName] isEqualToString:@"TikiTV"] ? kCGDirectMainDisplay : fullscreenDisplayId;
		NSOpenGLPixelFormatAttribute	attributes[] = {
			NSOpenGLPFAFullScreen,
			//														NSOpenGLPFAScreenMask, CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
			//														NSOpenGLPFAScreenMask, CGDisplayIDToOpenGLDisplayMask(reallyFSDisplayID),
			NSOpenGLPFAScreenMask, CGDisplayIDToOpenGLDisplayMask(fullscreenDisplayId),														
			
			NSOpenGLPFANoRecovery,
			NSOpenGLPFADoubleBuffer,
			NSOpenGLPFAAccelerated,
			//														NSOpenGLPFADepthSize, 24,
			NSOpenGLPFAAlphaSize, 8,
			(NSOpenGLPixelFormatAttribute) 0
		};
		fullscreenContext = [[[self class] alloc] initWithAttributes:attributes shareContext:nil];
		//		if (![[[NSProcessInfo processInfo] processName] isEqualToString:@"TikiTV"]) {
		//			NSLog(@"SETTING VBL");
		/* request this context sync with VBL */
		long							value = 1;
		[[fullscreenContext openGLContext] setValues:(const GLint *)&value forParameter:NSOpenGLCPSwapInterval];
		
		//		}
		NSLog(@"fullscreen is %@ on %d", fullscreenContext, fullscreenDisplayId);
		
		if (fullscreenContext == nil) {
			NSLog(@"cannot create fullscreen context!");
		}
	}
	return fullscreenContext;
}

+ (VSOpenGLContext*)context
{
	NSOpenGLPixelFormatAttribute	attributes[] = {
		NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFADepthSize, 24,
		(NSOpenGLPixelFormatAttribute) 0
	};
	return [[[[self class] alloc] initWithAttributes:attributes shareContext:[[self class] fullscreenContext]] autorelease];
}

- (id)initWithAttributes:(NSOpenGLPixelFormatAttribute*)attributes shareContext:(VSOpenGLContext*)share
{
	self = [super init];
	if (self != nil) {
		[self setValue:[[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease] forKey:@"_pixelFormat"];
		[self setValue:[[[NSOpenGLContext alloc] initWithFormat:[self pixelFormat] shareContext:[share openGLContext]] autorelease] forKey:@"_context"];
		
		
	}
	return self;
}

- (void) dealloc {
	[self setValue:nil forKey:@"_pixelFormat"];
	[self setValue:nil forKey:@"_context"];
	[self setValue:nil forKey:@"_renderer"];
	[super dealloc];
}

- (void)enterFullscreen
{
	[[self openGLContext] setFullScreen];
	_isFullscreen = YES;
}

- (BOOL)isFullscreen {
	return _isFullscreen;
}

- (void)exitFullscreen
{
	[[self openGLContext] clearDrawable];
	_isFullscreen = NO;
}

- (void)flushBuffer
{
	[[self openGLContext] flushBuffer];
}

- (NSOpenGLPixelFormat*)pixelFormat
{
	return _pixelFormat;
}

- (NSOpenGLContext*)openGLContext
{
	return _context;
}

- (QCRenderer*)renderer
{
	return _renderer;
}

- (void)setPreview:(BOOL)preview
{
	_isPreview = preview;
}

- (BOOL)isPreview
{
	return _isPreview;
}


@end

@implementation VSTextureUnitTexture

- (NSOpenGLContext*)context
{
	return [[VSOpenGLContext fullscreenContext] openGLContext];
}

- (id)initWithTextureUnit:(GLenum)unit textureUnitIndex:(GLint)unitIndex name:(GLcharARB*)name base:(void*)base rowBytes:(int)rowBytes
{
	self = [super init];
	if (self != nil) {
		_textureUnit = unit;
		_textureUnitIndex = unitIndex;
		_textureName = name;
		CGLContextObj cgl_ctx =  [[self context] CGLContextObj];
		glGenTextures(1, &_textureID);
		ttv_check_gl_error();
		NSLog(@"new texture id is %d", _textureID);
		_base = base;
		_baseRowBytes = rowBytes;
	}
	return self;
}

- (void)deleteTexture {
	CGLContextObj cgl_ctx = [[self context] CGLContextObj];
	if (cgl_ctx != NULL && _textureID != 0) {
		glDeleteTextures(1, &_textureID);
		ttv_check_gl_error();
		_textureID = 0;
	}
}

- (void) dealloc {
	NSLog(@"TUT, dealloc before ctx %X, texture %d", (int)[[self context] CGLContextObj], _textureID);
	[self deleteTexture];
	NSLog(@"TUT, dealloc after ctx %X, texture %d", (int)[[self context] CGLContextObj], _textureID);
	[super dealloc];
}

- (GLuint)textureID
{
	return _textureID;
}

- (void)uploadPlane:(void*)data size:(NSSize)size rowBytes:(GLint)rowBytes program:(GLhandleARB)program context:(CGLContextObj)cgl_ctx
{
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	ttv_check_gl_error();
	
	glActiveTexture(_textureUnit);
	ttv_check_gl_error();
	GLint varIndex = glGetUniformLocationARB(program, _textureName);
	ttv_check_gl_error();	
	glUniform1iARB(varIndex, _textureUnitIndex);  /* Bind varname to texture unit at index */
	ttv_check_gl_error();	
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, _textureID);	
	ttv_check_gl_error();
	
	ttv_check_gl_error();
	
	ttv_check_gl_error();	
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	ttv_check_gl_error();
	
	//	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	//	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	ttv_check_gl_error();
	
	//	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);	
	ttv_check_gl_error();	
	//	glPixelStorei(GL_UNPACK_ROW_LENGTH, rowBytes);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	ttv_check_gl_error();
	
	
	
	if (_pbo == 0) {
		glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
		ttv_check_gl_error();
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_CACHED_APPLE); //VRAM
		//		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_SHARED_APPLE); //AGP
		
		glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_LUMINANCE, _baseRowBytes, size.height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, _base);
		ttv_check_gl_error();
		glGenBuffers(1, &_pbo);
		ttv_check_gl_error();
		
		glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, _pbo);
		ttv_check_gl_error();
		glBufferData(GL_PIXEL_UNPACK_BUFFER_ARB, _baseRowBytes*size.height, _base, GL_STREAM_DRAW);
		ttv_check_gl_error();
		glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, 0);
		ttv_check_gl_error();
	}
	glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, _pbo);
	ttv_check_gl_error();
	glBufferData(GL_PIXEL_UNPACK_BUFFER_ARB, _baseRowBytes*size.height, NULL, GL_STREAM_DRAW);
	ttv_check_gl_error();
	void* ioMem = glMapBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, GL_WRITE_ONLY);
	ttv_check_gl_error();
	void *ptr = data;
	for(int i = 0; i < size.height; i++) {
		memcpy(ioMem, ptr, rowBytes);
		ioMem += _baseRowBytes;
		ptr += rowBytes;
	}
	glUnmapBuffer(GL_PIXEL_UNPACK_BUFFER_ARB);
	ttv_check_gl_error();
	glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, 0);
	ttv_check_gl_error();
	
	_cachedSize = size;
	_cachedRowBytes = rowBytes;
}

- (void)uploadTextureInContext:(CGLContextObj)cgl_ctx {
	if (_cachedSize.width == 0 || _cachedSize.height == 0)
		return;
	[self bindInContext:cgl_ctx];
	glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, _pbo);
	ttv_check_gl_error();
	glTexSubImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, 0, 0, _baseRowBytes, _cachedSize.height, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0);
	ttv_check_gl_error();	
	glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, 0);
	ttv_check_gl_error();
}

- (void)bindInContext:(CGLContextObj)cgl_ctx
{
	//	NSLog(@"binding %d, %d, %s", _textureUnit, _textureUnitIndex, _textureName);
	glActiveTexture(_textureUnit);
	ttv_check_gl_error();
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, _textureID);
	ttv_check_gl_error();
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	ttv_check_gl_error();
}

- (void)unBindInContext:(CGLContextObj)cgl_ctx
{
	//	NSLog(@"binding %d, %d, %s", _textureUnit, _textureUnitIndex, _textureName);
	glActiveTexture(_textureUnit);
	ttv_check_gl_error();	
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
	ttv_check_gl_error();
	glDisable(GL_TEXTURE_RECTANGLE_EXT);
	ttv_check_gl_error();
}
@end



@implementation VSAbstractProgramTexture

- (void)_printInfoLog:(GLhandleARB)object pname:(GLenum)pname context:(CGLContextObj)cgl_ctx
{
	GLint status;
	char *s;
	int len = 32768;
	
	glGetObjectParameterivARB(object, pname, &status);
	s = malloc(len);
	glGetInfoLogARB(object, len, NULL, s);
	printf("Status %d, Log: %s\n", (int)status, s);
	free(s);
}

- (id)initWithProgramText:(const GLcharARB*)text context:(CGLContextObj)cgl_ctx
{
	if ((self = [super init]) != nil) {
		_programHandle = glCreateProgramObjectARB();
		_cgl_ctx = cgl_ctx;
		ttv_check_gl_error();
		
		GLhandleARB shaderHandle = glCreateShaderObjectARB(GL_FRAGMENT_SHADER_ARB);
		ttv_check_gl_error();
		glShaderSourceARB(shaderHandle, 1, &text, (const GLint *)NULL);
		glCompileShaderARB(shaderHandle);
		[self _printInfoLog:shaderHandle pname:GL_OBJECT_COMPILE_STATUS_ARB context:cgl_ctx];
		
		glAttachObjectARB(_programHandle, shaderHandle);
		glLinkProgramARB(_programHandle);
		[self _printInfoLog:_programHandle pname:GL_OBJECT_LINK_STATUS_ARB context:cgl_ctx];
		int length = 752*480*2;
		void *buffer = malloc(length);
		_data = [[NSData dataWithBytesNoCopy:buffer length:length freeWhenDone:YES] retain];
	}
	return self;
}

- (void)dealloc {
	CGLContextObj cgl_ctx = _cgl_ctx;
	
	if (cgl_ctx != NULL && _programHandle != 0) {
		NSLog(@"deleting program object %X", _programHandle);
		glDeleteObjectARB(_programHandle);
		_programHandle = 0;
		_cgl_ctx = NULL;
	}
	
	[super dealloc];
}

- (NSData*)data {
	return _data;
}

- (BOOL) invalid {
	return _invalid;
}

- (void)invalidate {
	//	[TTVTextureSource lockGL];
	_invalid = YES;
	//	[TTVTextureSource unlockGL];
}

- (NSTimeInterval)decodeTime {
	return _decodeTime;
}

- (void)uploadPicture:(AVPicture*)picture size:(NSSize)size decodeTime:(NSTimeInterval)time context:(CGLContextObj)cgl_ctx
{
	if (picture->linesize[0] < 0) {
		return;
	}
	_decodeTime = time;
	glUseProgramObjectARB(_programHandle);
	ttv_check_gl_error();
	//	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
	//	ttv_check_gl_error();
	//	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_CACHED_APPLE); //VRAM
	//	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_SHARED_APPLE); //AGP
	ttv_check_gl_error();
	
	_cachedSize = size;
}

- (void)drawInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx
{
#if 1
	//	if (_dl == 0) {
	//		_dl = glGenLists(1);
	//		glNewList(_dl,GL_COMPILE);
	glBegin( GL_QUADS );
	glTexCoord2d(0.0,_cachedSize.height); glVertex2d(rect.origin.x, rect.origin.y);
	glTexCoord2d(_cachedSize.width,_cachedSize.height); glVertex2d(rect.origin.x+rect.size.width, rect.origin.y);
	glTexCoord2d(_cachedSize.width,0.0); glVertex2d(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);
	glTexCoord2d(0.0,0.0); glVertex2d(rect.origin.x, rect.origin.y+rect.size.height);
	glEnd();
	//		glEndList();
	//	} else {
	//		glCallList(_dl);
	//	}
#endif	
	ttv_check_gl_error();
}

- (void)previewInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx
{
	[self drawInRect:rect context:cgl_ctx];
}

- (NSOpenGLContext*)context
{
	return [[VSOpenGLContext fullscreenContext] openGLContext];
}

- (void)uploadTextureInContext:(CGLContextObj)cgl_ctx {
}

- (void)setAdjustments:(float*)adjust context:(CGLContextObj)cgl_ctx {
	GLint varIndex = glGetUniformLocationARB(_programHandle, "adjust");
	if (varIndex != -1) {
		glUseProgramObjectARB(_programHandle);
		ttv_check_gl_error();		
		glUniform4fv(varIndex, 4, adjust);
		ttv_check_gl_error();
		glUseProgramObjectARB(0);
		ttv_check_gl_error();		
	}
}

@end


@implementation VSYUVProgramTexture

- (id)initWithContext:(CGLContextObj)xxx_cgl_ctx;
{
	CGLContextObj cgl_ctx = [[self context] CGLContextObj];
	GLcharARB *yuv_program =
	"uniform sampler2DRect Ytex;\n"
	"uniform sampler2DRect Utex,Vtex;\n"
	"void main(void) {\n"
	"  float nx,ny,r,g,b,y,u,v,d;\n"
	"  vec4 txl,ux,vx;"
	"  nx=gl_TexCoord[0].x;\n"
	"  ny=gl_TexCoord[0].y;\n"
	"  y=texture2DRect(Ytex,vec2(nx,ny)).r;\n"	  
	"  u=texture2DRect(Utex,vec2(nx/2.0,ny/2.0)).r;\n"
	"  v=texture2DRect(Vtex,vec2(nx/2.0,ny/2.0)).r;\n"
	
	"  y=1.1643*(y-0.0625);\n"
	"  u=u-0.5;\n"
	"  v=v-0.5;\n"
	
	"  r=y+1.5958*v;\n"
	"  g=y-0.39173*u-0.81290*v;\n"
	"  b=y+2.017*u;\n"
	
	"  gl_FragColor=vec4(r, g, b, 1.0);\n"
	"}\n";
	if ((self = [super initWithProgramText:yuv_program context:cgl_ctx]) != nil) {
		AVPicture picture;
		avpicture_fill(&picture, (uint8_t*)[_data bytes], PIX_FMT_YUV420P, 752, 480);
		_textures = [[NSArray arrayWithObjects:
					  [[[VSTextureUnitTexture alloc] initWithTextureUnit:GL_TEXTURE1 textureUnitIndex:1 name:"Utex" base:picture.data[2] rowBytes:picture.linesize[2]] autorelease],
					  [[[VSTextureUnitTexture alloc] initWithTextureUnit:GL_TEXTURE2 textureUnitIndex:2 name:"Vtex" base:picture.data[1] rowBytes:picture.linesize[1]] autorelease],
					  [[[VSTextureUnitTexture alloc] initWithTextureUnit:GL_TEXTURE0 textureUnitIndex:0 name:"Ytex" base:picture.data[0] rowBytes:picture.linesize[0]] autorelease],
					  nil] retain];
	}
	return self;
}

- (void)dealloc {
	[_textures release];
	[super dealloc];
}


- (void)uploadPicture:(AVPicture*)picture size:(NSSize)size decodeTime:(NSTimeInterval)time context:(CGLContextObj)cgl_ctx
{
	[super uploadPicture:picture size:size decodeTime:time context:cgl_ctx];
	NSSize hsize = NSMakeSize(size.width/2, size.height/2);
	int index_map[] = { 1, 2, 0 };
	NSSize size_map[] = { hsize, hsize, size };
	for(int i = 0; i < 3; i++) {
		[[_textures objectAtIndex:i] uploadPlane:picture->data[index_map[i]] size:size_map[i] rowBytes:picture->linesize[index_map[i]] program:_programHandle context:cgl_ctx];
	}
}

- (void)uploadTextureInContext:(CGLContextObj)cgl_ctx {
	for(int i = 0; i < 3; i++) {
		[[_textures objectAtIndex:i] uploadTextureInContext:cgl_ctx];
	}
}

- (void)drawInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx
{
	if (_cachedSize.width == 0 || _cachedSize.height == 0) {
		//		return;
	}
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	for(int i = 0; i < [_textures count]; i++) {
		[[_textures objectAtIndex:i] bindInContext:cgl_ctx];
	}
	glUseProgramObjectARB(_programHandle);
	ttv_check_gl_error();
	
#if 0
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);	
	glDisable(GL_TEXTURE_RECTANGLE_EXT);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);		
	glDisable(GL_TEXTURE_RECTANGLE_EXT);
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
	glDisable(GL_TEXTURE_RECTANGLE_EXT);		
	ttv_check_gl_error();
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND);
	glBlendFunc(GL_ONE, GL_ZERO);
#endif
	
	//	glDisable(GL_TEXTURE_RECTANGLE_EXT);
	glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND );
	//	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
	ttv_check_gl_error();
	glColor4f(1.0, 1.0, 1.0, 0.0);
	ttv_check_gl_error();
	[super drawInRect:rect context:cgl_ctx];
	ttv_check_gl_error();
	
	for(int i = 0; i < [_textures count]; i++) {
		[[_textures objectAtIndex:i] unBindInContext:cgl_ctx];
	}
	glUseProgram(0);
	glDisable(GL_TEXTURE_RECTANGLE_EXT);	
}

@end


@implementation VSAlphaProgramTexture

- (id)initWithContext:(CGLContextObj)xxx_cgl_ctx;
{
	CGLContextObj cgl_ctx = [[self context] CGLContextObj];
	GLcharARB *alpha_program =
	"uniform sampler2DRect Ytex;\n"
	"uniform vec4 adjust;\n"
	"void main(void) {\n"
	"  float y;\n"
	
	"  y=texture2DRect(Ytex, gl_TexCoord[0].xy).r;\n"
	
	/* these are the scale factors for the alpha */
	//		  "  gl_FragColor=vec4(gl_Color.r, gl_Color.g, gl_Color.b, y);\n"
	//		  "  gl_FragColor=vec4(y, y, y, y*1.35);\n"
	//		  "  gl_FragColor=vec4(1.0, 1.0, 1.0, 1.0);\n"
	//offset, scale, exponent
	"  gl_FragColor=vec4(0.0, 0.0, 0.0, pow((y-adjust[0]), adjust[2])*adjust[1]);\n"
	//		  "  gl_FragColor=vec4(0.0, 0.0, 0.0, 1.0-y*5.0);\n"
	//		  "  gl_FragColor = gl_Color;\n"
	"}\n";
	
	if ((self = [super initWithProgramText:alpha_program context:cgl_ctx]) != nil) {
		_texture = [[VSTextureUnitTexture alloc] initWithTextureUnit:GL_TEXTURE0 textureUnitIndex:0 name:"Ytex" base:(uint8_t*)[_data bytes] rowBytes:752];
	}
	return self;
}

- (void)dealloc {
	[_texture release];
	[super dealloc];
}


- (void)uploadPicture:(AVPicture*)picture size:(NSSize)size decodeTime:(NSTimeInterval)time context:(CGLContextObj)cgl_ctx
{
	
	if (size.width == 0 || size.height == 0) {
		return;
	}
	
	[super uploadPicture:picture size:size decodeTime:time context:cgl_ctx];
	[_texture uploadPlane:picture->data[0] size:size rowBytes:picture->linesize[0] program:_programHandle context:cgl_ctx];
}

- (void)uploadTextureInContext:(CGLContextObj)cgl_ctx {
	[_texture uploadTextureInContext:cgl_ctx];
}

- (void)drawInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx
{
	[_texture bindInContext:cgl_ctx];
	glUseProgramObjectARB(_programHandle);	
	
	glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND );
	//	glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE );
	ttv_check_gl_error();
	glColor4f(0.0, 0.0, 0.0, 1.0);
	ttv_check_gl_error();
	
	[super drawInRect:rect context:cgl_ctx];
	ttv_check_gl_error();
	
	[_texture unBindInContext:cgl_ctx];	
	glUseProgram(0);	
}

- (void)previewInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx
{
	//	[super previewInRect:rect context:cgl_ctx];
	glUseProgram(0);
	glColor4f(1.0, 1.0, 1.0, 1.0);
	glDisable(GL_TEXTURE_RECTANGLE_EXT);
	glBegin( GL_QUADS );
	glTexCoord2d(0.0,_cachedSize.height); glVertex2d(rect.origin.x, rect.origin.y);
	glTexCoord2d(_cachedSize.width,_cachedSize.height); glVertex2d(rect.origin.x+rect.size.width, rect.origin.y);
	glTexCoord2d(_cachedSize.width,0.0); glVertex2d(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);
	glTexCoord2d(0.0,0.0); glVertex2d(rect.origin.x, rect.origin.y+rect.size.height);		
	glEnd();
	glEnable(GL_TEXTURE_RECTANGLE_EXT);	
	glUseProgram(_programHandle);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	//	glBlendFunc(GL_ONE, GL_ONE);
	[_texture bindInContext:cgl_ctx];
	
	glBegin( GL_QUADS );
	glTexCoord2d(0.0,_cachedSize.height); glVertex2d(rect.origin.x, rect.origin.y);
	glTexCoord2d(_cachedSize.width,_cachedSize.height); glVertex2d(rect.origin.x+rect.size.width, rect.origin.y);
	glTexCoord2d(_cachedSize.width,0.0); glVertex2d(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);
	glTexCoord2d(0.0,0.0); glVertex2d(rect.origin.x, rect.origin.y+rect.size.height);		
	glEnd();
	ttv_check_gl_error();
	glUseProgram(0);
	ttv_check_gl_error();	
	
}

@end


static	NSLock *_glLock = nil;

@implementation TTVTextureSource

+ (void)lockGL {
	if (_glLock == nil) {
		_glLock = [[NSLock alloc] init];
	}
	[_glLock lock];
}

+ (void)unlockGL {
	[_glLock unlock];
}

@end




@implementation TTVVideoStream 

+ (int)queueSize
{
	return 12;
}

- (id)initWithTextureClass:(Class)textureClass {
	self = [super init];
	if (self != nil) {
		_buffers = [[NSMutableArray array] retain];
		_freeBuffers = [[VSBufferQueue alloc] init];
		_decodedBuffers = [[VSBufferQueue alloc] init];
		_timer = [[TTVTimerStrip alloc] initWithSampleCount:210];
		_adjust[0] = 0.0;
		_adjust[1] = 8.8;
		_adjust[2] = 3.3;
		_adjust[3] = 1.0;
	}
	for(int i = 0; i < [[self class] queueSize]; i++) {
		[_buffers addObject:[[[textureClass alloc] initWithContext:NULL] autorelease]];
		[_freeBuffers enqueue:[_buffers objectAtIndex:i]];
	}
	return self;
}


- (void)fillBuffer:(AVPicture*)decodedPicture size:(NSSize)size decodeTime:(NSTimeInterval)time context:(CGLContextObj)cgl_ctx {
	VSAbstractProgramTexture *texture = [_freeBuffers dequeue];
	//	NSLog(@"FILLING 0x%X", (int)texture);	
	[texture uploadPicture:decodedPicture size:size decodeTime:time context:cgl_ctx];	
	[_decodedBuffers enqueue:texture];
}

- (void)uploadTextureInContext:(CGLContextObj)cgl_ctx {
	[[self currentTexture] setAdjustments:_adjust context:cgl_ctx];
	[[self currentTexture] uploadTextureInContext:cgl_ctx];
}

- (void)previewInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx {
	//	NSLog(@"DRAWING 0x%X", (int)[self currentTexture]);
	[[self currentTexture] previewInRect:rect context:cgl_ctx];
	[_timer drawInRect:rect context:cgl_ctx];
}

- (void)advance {
	if ([_decodedBuffers count] == 0) {
		return;
	}
	VSAbstractProgramTexture *data = [_decodedBuffers dequeue];
	
	if (__current_frame != nil) {	
		[_timer tick:[__current_frame decodeTime]];
	}
	
	if (data != nil) {
		if (__current_frame != nil) {
			[_freeBuffers enqueue:__current_frame];
		}	
		__current_frame = data;
	}
}

- (void)reset {
	while([_decodedBuffers count] > 0) {
		VSAbstractProgramTexture *data = [_decodedBuffers dequeue];
		[_freeBuffers enqueue:data];
	}
}

- (VSAbstractProgramTexture*)currentTexture {
	if ([__current_frame invalid]) {
		return nil;
	}
	return __current_frame;	
}

- (int)fieldIndex:(NSString*)field {
	static NSDictionary *fields = nil;
	if (fields == nil) {
		fields = [[NSDictionary dictionaryWithObjectsAndKeys:
				   [NSNumber numberWithInt:0], @"bias",
				   [NSNumber numberWithInt:1], @"scale",
				   [NSNumber numberWithInt:2], @"exp",
				   nil] retain];
	}
	return [[fields objectForKey:field] intValue];
}

- (void)decrementField:(NSString*)field {
	_adjust[[self fieldIndex:field]] -= 0.25;
	NSLog(@"fields %f, %f, %f, %f", _adjust[0], _adjust[1], _adjust[2], _adjust[3]);
}

- (void)incrementField:(NSString*)field {
	_adjust[[self fieldIndex:field]] += 0.25;
	NSLog(@"fields %f, %f, %f, %f", _adjust[0], _adjust[1], _adjust[2], _adjust[3]);	
}


@end

@implementation TTVRenderer
- (id)init {
	self = [super init];
	if (self != nil) {
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}


- (void)drawOutput:(NSRect)rect context:(NSOpenGLContext*)context pictureSource:(TTVPictureSource*)pictureSource {
	CGLContextObj cgl_ctx = [context CGLContextObj];
	for(int i = 0; i < 3; i++) {
		[[pictureSource streamAtIndex:i] uploadTextureInContext:cgl_ctx];
		ttv_check_gl_error();
	}
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	ttv_check_gl_error();	
	
	glDisable(GL_BLEND);
	ttv_check_gl_error();	
	
	[[[pictureSource streamAtIndex:2] currentTexture] drawInRect:rect context:[context CGLContextObj]];
	ttv_check_gl_error();	
	glEnable(GL_BLEND);
	ttv_check_gl_error();
	
	glBlendFunc(GL_ONE, GL_SRC_ALPHA);
	ttv_check_gl_error();	
	
	[[[pictureSource streamAtIndex:1] currentTexture] drawInRect:rect context:[context CGLContextObj]];
	ttv_check_gl_error();
	
	glBlendFunc(GL_ONE_MINUS_DST_ALPHA, GL_ONE);
	ttv_check_gl_error();
	
	[[[pictureSource streamAtIndex:0] currentTexture] drawInRect:rect context:[context CGLContextObj]];
	ttv_check_gl_error();
	
#if 1
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);	
	glDisable(GL_TEXTURE_RECTANGLE_EXT);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);		
	glDisable(GL_TEXTURE_RECTANGLE_EXT);
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
	glDisable(GL_TEXTURE_RECTANGLE_EXT);		
	ttv_check_gl_error();
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND);
	glBlendFunc(GL_ONE, GL_ZERO);
#endif
	
}

@end


@implementation TTVBrowserItem
- initWithPath:(NSString*)path { 
	self = [super init];
	if (self != nil) {
		_path = [path retain];
	}
	return self;
}
- (NSString *) imageRepresentationType { return IKImageBrowserPathRepresentationType; }
//- (NSString *) imageRepresentationType { return IKImageBrowserQTMoviePathRepresentationType; }
- (NSString *) imageUID { return [self path]; }
//- (id)imageRepresentation { return @"/Users/jesse/projects/tikirobotreader/TikiTV/foo.png"; }
- (id)imageRepresentation {
	NSString *proxyPath = [[[self path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@".%@001.png", [[[self path] lastPathComponent] stringByDeletingPathExtension]]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:proxyPath] == NO) {
		NSString *createPath = [[[self path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@".%@%%03d.png", [[[self path] lastPathComponent] stringByDeletingPathExtension]]];	
		NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/local/bin/ffmpeg" arguments:[NSArray arrayWithObjects:@"-i", [self path],  @"-vframes",  @"1", createPath, nil]];
		[task waitUntilExit];
	}
	return proxyPath;
}
- (NSString *) imageSubtitle { return [[self path] lastPathComponent]; }
- (NSString*)path { 
	//NSLog(@"returning path %@", _path);
	return _path;
}
@end


@implementation TTVTimerStrip
- (id)initWithSampleCount:(int)count {
	self = [super init];
	if (self != nil) {
		_sampleCount = count;
		_sampleSize = (sizeof *_samples);
		_samples = calloc(_sampleSize, _sampleCount);
	}
	return self;
}
- (void) dealloc {
	free(_samples);
	_samples = (void*)0x9;
	[super dealloc];
}

- (void)tick:(NSTimeInterval)time {
	memmove(_samples+1, _samples, (_sampleCount-1)*_sampleSize);
	int ms = time*1000.0;
	if (ms > 19) {
		ms = 19;
	}
	if (ms < 0) {
		ms  = 0;
	}
	_samples[0] = ms;
}

- (void)drawInRect:(NSRect)rect context:(CGLContextObj)cgl_ctx {
	if (!_listBase) {
		_listBase = glGenLists(21);
		for(int i = 0; i < 20; i++) {
			glNewList(_listBase + i, GL_COMPILE);
			if (i >= 18) {
				glColor4f(1.0, 0.0, 0.0, 1.0);
			}
			else {
				glColor4f(1.0, 1.0, 1.0, 1.0);
			}
			glRecti(0, 0, 1, i);
			glEndList();
		}
	}
	glPushMatrix();
	glTranslatef(NSMinX(rect) +0.375, NSMinY(rect), 0);
	for(int i = 0; i < _sampleCount; i++) {
		glTranslatef(1, 0, 0);
		glCallList(_samples[i]);
	}
	glPopMatrix();
	
}
@end



@implementation TTVPacket

- (AVPacket*)packetPtr {
	return &_pkt;
}

- (void *)dataPtr {
	return _pkt.data;
}
- (int)dataSize {
	return _pkt.size;
}

@end

NSLock *__ffmpegLock = nil;

@implementation TTVInputContext

+ (void)_lockFFMPEG {
	if (__ffmpegLock == nil) {
		__ffmpegLock = [[NSLock alloc] init];
	}
	[__ffmpegLock lock];
}

+ (void)_unlockFFMPEG {
	[__ffmpegLock unlock];
}

- (void)lockFFMPEG {
	[[self class] _lockFFMPEG];
}
- (void)unlockFFMPEG {
	[[self class] _unlockFFMPEG];
}

- (BOOL)_contextValid {
	return _ffmpegContext && _ffmpegContext->streams && _ffmpegContext->streams[0] && _ffmpegContext->streams[0]->codec;
}

- (BOOL)_codecValid {
	return [self _contextValid] && _codecOpened;
}

- (id)initWithFile:(NSString*)path {
	self = [super init];
	if (self != nil) {
		[self lockFFMPEG];
		av_register_all(); /* this only does stuff the first time it's called */
		int rv = av_open_input_file(&_ffmpegContext, [path fileSystemRepresentation], NULL, 0, NULL);
		if (rv == 0 && [self _contextValid]) {
			AVCodec *codec = avcodec_find_decoder(_ffmpegContext->streams[0]->codec->codec_id);
			rv = avcodec_open(_ffmpegContext->streams[0]->codec, codec);
			if (rv == 0) {
				_ffmpegFrame = avcodec_alloc_frame();
				_codecOpened = YES;
			}
		}
		[self unlockFFMPEG];
	}
	if (_codecOpened == NO) {
		[self dealloc];
		self = nil;
	}
	return self;
}
- (void)dealloc {
	if ([self _codecValid]) {
		[self lockFFMPEG];
		avcodec_close(_ffmpegContext->streams[0]->codec);
		av_freep(&_ffmpegFrame);
		[self unlockFFMPEG];
		TTV_INVALIDATE(_ffmpegFrame);
		_codecOpened = NO;
	}
	if (_ffmpegContext) {
		[self lockFFMPEG];
		av_close_input_file(_ffmpegContext);
		[self unlockFFMPEG];
	}
	TTV_INVALIDATE(_ffmpegContext);
	[super dealloc];
}
- (void)seekToOffset:(int)offset {
}

- (void)gotoBeginning {
	if ([self _codecValid]) {
		[self lockFFMPEG];		
		avcodec_flush_buffers(_ffmpegContext->streams[0]->codec);
		[self unlockFFMPEG];		
		url_fseek(_ffmpegContext->pb, 0, SEEK_SET);
	}
}
- (void)skipForward {
}
- (void)skipBackward {
}
- (TTVPacket*)readNextFrame {
	TTVPacket *packet = nil;
	if ([self _codecValid]) {
		packet = [[[TTVPacket alloc] init] autorelease];
		int rv = av_read_frame(_ffmpegContext, [packet packetPtr]);
		if (rv < 0) {
			packet = nil;
		}
	}
	return packet;
}

- (AVFrame*)decodeFrame:(TTVPacket*)packet {
	AVFrame *frame = NULL;
	if ([self _codecValid]) {
		int got_frame = 0;
		avcodec_decode_video(_ffmpegContext->streams[0]->codec, _ffmpegFrame, &got_frame, [packet dataPtr], [packet dataSize]);
		if (got_frame) {
			frame = _ffmpegFrame;
		}
	}
	return frame;
}

- (NSSize)currentSize {
	if ([self _codecValid]) {
		return NSMakeSize(_ffmpegContext->streams[0]->codec->width, _ffmpegContext->streams[0]->codec->height);
	}
	else {
		return NSZeroSize;
	}
}

@end

@implementation TTVMediaReader

+ (TTVMediaReader*)mediaReaderForFile:(NSString*)path {
	Class readerClass = [[path pathExtension] isEqualToString:@"ttv_seq"] ? [TTVSequenceReader class] : [TTVFileReader class];
	return [[[readerClass alloc] initWithFile:path] autorelease];
}

- (id)initWithFile:(NSString*)path {
	self = [super init];
	if (self != nil) {
		TTV_KVC_SET(filePath, path);
		//_filePath = [path retain];
	}
	return self;
}
- (void)dealloc {
	TTV_KVC_SET(filePath, nil);
	TTV_KVC_SET(inputContext, nil);
	[super dealloc];
}
- (NSString*)filePath {
	return _filePath;
}
- (void)skipForward {
}
- (void)skipBackward {
}
- (TTVPacket*)readNextFrame {
	return [[self inputContext] readNextFrame];
}
- (TTVInputContext *)inputContext {
	return _inputContext;
}
- (NSSize)currentSize {
	return [_inputContext currentSize];
}
- (AVFrame*)decodeNextFrame {
	return [[self inputContext] decodeFrame:[self readNextFrame]];
}

@end

@implementation TTVFileReader
- (id)initWithFile:(NSString*)path {
	self = [super initWithFile:path];
	if (self != nil) {
		TTV_KVC_SET(inputContext, [[[TTVInputContext alloc] initWithFile:path] autorelease]);
	}
	return self;
}

- (void)skipForward {
}
- (void)skipBackward {
}
- (TTVPacket*)readNextFrame {
	TTVPacket *pkt = [super readNextFrame];
	if (pkt == nil) {
		[[self inputContext] gotoBeginning];
		pkt = [super readNextFrame];
	}
	return pkt;
}

@end

@implementation TTVSequenceReader

- (id)initWithFile:(NSString*)path {
	self = [super initWithFile:path];
	if (self != nil) {
		NSError *error = nil;
		NSString *contents = [NSString stringWithContentsOfFile:[self filePath] encoding:NSASCIIStringEncoding error:&error];
		if (contents != nil && error == nil) {
			NSArray *tmp = [contents componentsSeparatedByString:@"\n"];
			NSMutableArray *newPlaylist = [[NSMutableArray array] retain];
			for(int i = 0; i < [tmp count]; i++) {
				NSString *path = [[VSFileLibrary library] pathForFilename:[tmp objectAtIndex:i]];
				if ([[NSFileManager defaultManager] fileExistsAtPath:path] == YES) {
					[newPlaylist addObject:[tmp objectAtIndex:i]];
				}
			}
			_sequence = newPlaylist;
			if ([_sequence count]) {
				TTV_KVC_SET(inputContext, [[[TTVInputContext alloc] initWithFile:[self _currentFile]] autorelease]);
			}
		}
		else {
			self = nil;
		}
	}
	return self;
}
- (void)dealloc {
	TTV_KVC_SET(reader, nil);
	TTV_KVC_SET(sequence, nil);
	[super dealloc];
}
- (BOOL)valid {
	return [_sequence count] > 0;
}	
- (void)skipForward {
	if ([self valid]) {
		_sequenceIndex++;
		if (_sequenceIndex >= [_sequence count]) {
			_sequenceIndex = 0;
		}
	}
}	

- (void)skipBackward {
	if ([self valid]) {
		_sequenceIndex++;
		if (_sequenceIndex >= [_sequence count]) {
			_sequenceIndex = 0;
		}
	}	
}

- (NSString*)_currentFile {
	NSString *current = nil;
	if ([_sequence count] && _sequenceIndex < [_sequence count]) {
		current = [[[VSFileLibrary library] libraryPath] stringByAppendingPathComponent:[_sequence objectAtIndex:_sequenceIndex]];
	}
	return current;
}

- (AVFrame*)decodeNextFrame {
	AVFrame *frame = NULL;
	if ([self valid]) {
		TTVPacket *pkt = [self readNextFrame];
		if (pkt == nil) {
			[self skipForward];
			TTV_KVC_SET(inputContext, [[[TTVInputContext alloc] initWithFile:[self _currentFile]] autorelease]);
			pkt = [self readNextFrame];
		}
		frame = [[self inputContext] decodeFrame:pkt];
	}
	return frame;
}


@end


@implementation TTVDecoderThread

- (void)_changeMediaFile:(NSString*)path {
	TTV_KVC_SET(reader, [TTVMediaReader mediaReaderForFile:path]);
}

- (id)initWithFile:(NSString*)path stream:(TTVVideoStream*)stream {
	self = [super init];
	if (self != nil) {
		[self _changeMediaFile:path];
		TTV_KVC_SET(stream, stream);
		_commandQueue = [[VSBufferQueue alloc] init];
		_lock = [[NSRecursiveLock alloc] init];
		_context = [[VSOpenGLContext context] retain];
		[NSThread detachNewThreadSelector:@selector(_decodeLoop) toTarget:self withObject:nil];
	}
	return self;
}
- (void)dealloc {
	TTV_KVC_SET(reader, nil);
	TTV_KVC_SET(stream, nil);
	TTV_RELEASE(_commandQueue);
	TTV_RELEASE(_lock);
	TTV_RELEASE(_context);
	[super dealloc];
}

- (void)lock {
	[_lock lock];
}

- (void)unlock {
	[_lock unlock];
}
- (CGLContextObj)CGLContextObj {
	return [[_context openGLContext] CGLContextObj];
}
- (void)_deferredExecutionForSelector:(SEL)cmd withObject:(id)object {
	SEL selector = NSSelectorFromString([@"_" stringByAppendingString:NSStringFromSelector(cmd)]);
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[[self class] instanceMethodSignatureForSelector:selector]];
	[invocation setSelector:selector];
	[invocation setTarget:self];
	[invocation setArgument:&object atIndex:2];
	[invocation retainArguments];
	[_commandQueue enqueue:[invocation retain]];
}


- (void)changeMediaFile:(NSString*)path {
	[self _deferredExecutionForSelector:_cmd withObject:path];
}

- (void)_allDone:(id)sender {
	_allDone = YES;
}

- (void)allDone {	
	[self _deferredExecutionForSelector:@selector(allDone:) withObject:nil];
}

- (void)_setStream:(TTVVideoStream*)stream {
	TTV_KVC_SET(stream, stream);
}

- (void)setStream:(TTVVideoStream*)stream {
	[self _deferredExecutionForSelector:@selector(setStream:) withObject:stream];
}


- (void)_decodeLoop {
	while(_allDone == NO) {		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
		AVFrame *frame = [[self mediaReader] decodeNextFrame];
		NSTimeInterval decodeTime = [NSDate timeIntervalSinceReferenceDate] - start;
		if (frame != NULL) {
			[_stream fillBuffer:(AVPicture*)frame size:[[self mediaReader] currentSize] decodeTime:decodeTime context:[self CGLContextObj]];
		}
		while ([_commandQueue objectsAvailable]) {
			NSInvocation *invocation = [_commandQueue dequeue];
			[invocation invoke];
			[invocation release];
		}
		[pool release];
	}
}
- (TTVMediaReader*)mediaReader {
	TTVMediaReader *reader;
	[self lock];
	reader = _reader;
	[self unlock];
	return reader;
}
- (TTVVideoStream*)stream {
	TTVVideoStream *stream;
	[self lock];
	stream = _stream;
	[self unlock];
	return stream;	
}
- (NSString*)inputFilename {
	return [[self mediaReader] filePath];
}

@end


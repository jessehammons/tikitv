#import "VSOpenGLView.h"

#import <OpenGL/CGLMacro.h>

@implementation VSOpenGLView

- (void)reshape
{
	CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
	glViewport(0, 0, [self bounds].size.width, [self bounds].size.height);
}

@end

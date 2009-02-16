/* VSFileLibrary */

#import <Cocoa/Cocoa.h>

@interface VSFileLibrary : NSObject
{
	NSArray *_files;
}

+ (VSFileLibrary*)library;
- (NSString*)libraryPath;
- (NSString*)pathForRow:(int)row;
- (NSString*)pathForFilename:(NSString*)filename;
- (NSString*)filenameForRow:(int)row;
- (NSString*)pathForBookmark:(NSString*)mark;
- (NSString*)bookmarksPath;
- (void)rescan;
@end

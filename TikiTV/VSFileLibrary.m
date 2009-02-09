
#import "VSFileLibrary.h"

@implementation VSFileLibrary

+ (VSFileLibrary*)library
{
	static VSFileLibrary* library = nil;
	if (library == nil) {
		library = [[VSFileLibrary alloc] init];
	}
	return library;
}

- (id)init {
	self = [super init];
	if (self != nil) {
		NSArray *files = [[[NSFileManager defaultManager] directoryContentsAtPath:[self libraryPath]] retain];
		_files = [[files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"not SELF beginswith[c] '.' and (SELF endswith[c] '.m2v' or SELF endswith[c] '.mpg' or SELF endswith[c] '.ttv_seq' or SELF endswith[c] '.vob' or SELF endswith[c] '.ttvclips' or SELF endswith[c] '.ttv_multi' or SELF endswith[c] '.ttv_sheep' ) "]] retain];
		[[NSFileManager defaultManager] createDirectoryAtPath:[self bookmarksPath] attributes:nil];
	}
	return self;
}

- (NSString*)bookmarksPath {
	return [[self libraryPath] stringByAppendingPathComponent:@"bookmarks"];
}

- (NSString*)pathForBookmark:(NSString*)mark {
	return [[self bookmarksPath] stringByAppendingPathComponent:mark];
}

- (NSString*)traversedPathForBookmark:(NSString*)mark {
	NSString *path = [self pathForBookmark:mark];
	NSString *traversed = [[NSFileManager defaultManager] pathContentOfSymbolicLinkAtPath:path];
	if (traversed == nil) {
		traversed = path;
	}
	return traversed;
}


- (NSString*)pathForFilename:(NSString*)filename {
	return [[self libraryPath] stringByAppendingPathComponent:filename];
}

- (NSString*)libraryPath
{
//	return [[NSBundle mainBundle] pathForResource:@"selects" ofType:nil];
	return @"/selects/";
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [_files count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	return [_files objectAtIndex:rowIndex];
}

- (NSString*)pathForRow:(int)row {
	NSString *file = [_files objectAtIndex:row];
	return [[self libraryPath] stringByAppendingPathComponent:file];
}

- (NSString*)filenameForRow:(int)row {
	return [_files objectAtIndex:row];
}


- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	return NO;
}

@end

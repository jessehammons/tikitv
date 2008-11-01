//
//  tikitv_test.m
//  TikiTV2
//
//  Created by Jesse Hammons on 6/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "VSDecoder.h"
#import "TTVAppDelegate.h"
#import "VSFileLibrary.h"

#import "unistd.h"

@interface DecoderTest : NSObject
	NSMutableArray *_sources;
@end
@implementation DecoderTest

+ (NSString*)randomLibraryPath
{
	int rows = [[VSFileLibrary library] numberOfRowsInTableView:nil];
	int i = rand() % rows;
	return [[VSFileLibrary library] pathForRow:i];
}

- (id)init {
	if ((self = [super init]) != nil) {
		srand(getpid());
		_sources = [[NSMutableArray alloc] init];
		for(int i = 0; i < 5; i++) {
			[_sources addObject:[[TTVTextureSource alloc] initWithInputFilename:[[self class] randomLibraryPath]]];
			[[_sources objectAtIndex:i] startPreRoll];
			[[_sources objectAtIndex:i] startDecoding];
		}
	}
	return self;
}

- (void)advance {
	for(int i = 0; i < 5; i++) {
		[[_sources objectAtIndex:i] advanceAndUploadTexture: rand()%2];
	}
}

- (void)poke {
	int s = rand() % 5;
	[[_sources objectAtIndex:s] changeInputFilename:[[self class] randomLibraryPath]];
}

@end

int main(int argc, char **argv)
{
	int nframes =		20000000;
	int change_mod =	  20000;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	DecoderTest *test = [[DecoderTest alloc] init];
	for(int i = 0; i < nframes; i++) {
		[test advance];
		if ((i % change_mod) == 1) {
			[test poke];
		}
	}
	//sleep(5);
	[pool release];
	
	return 0;	
}
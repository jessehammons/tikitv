// cc -Wall -g -framework Foundation -O -o server do_test.m; cp server client

#import <Foundation/Foundation.h>

#if !defined(USE_SOCKETS)
 	#define USE_SOCKETS 1
#endif

#define DLEN (1024*1024*1)

@protocol ServerProtocol
- (void)setRandomSeed:(unsigned int)s;
- (long)getRandom;
- (bycopy NSData*)getData;
- (NSData*)getBigData;
- (bycopy NSString*)getString;
@end

@protocol ServerProtocol2
- (NSData*)pictureForStream:(int)index;
@end


@interface Server : NSObject <ServerProtocol>
@end

@implementation Server

- (NSData*)getData {
	return [@"hello!!!" dataUsingEncoding:NSASCIIStringEncoding];
}
- (NSData*)getBigData {
	return [NSMutableData dataWithLength:DLEN];
}
- (NSString*)getString {
	return @"hello!!!";
}

- (void)setRandomSeed:(unsigned int)s {
    srandom(s);
}

- (long)getRandom {
    return random();
}
@end

#define SERVER_PORT 15550
#define SERVER_NAME @"TEST"

void server(int argc, const char *argv[]) {
     NSPort *receivePort = nil;
     NSConnection *conn;
     id serverObj;

 #if USE_SOCKETS
     receivePort = [[NSSocketPort alloc] initWithTCPPort:SERVER_PORT];
 #else
     // Mach ports being "anonymous" and need to be named later
     receivePort = [[NSMachPort alloc] init];
 #endif
     conn = [[NSConnection alloc] initWithReceivePort:receivePort 
 sendPort:nil];
     serverObj = [[Server alloc] init];
     [conn setRootObject:serverObj];
 #if USE_SOCKETS
     // registration done by allocating the NSSocketPort
     printf("server configured to use sockets\n");
 #else
     if (![conn registerName:SERVER_NAME]) {
 	printf("server: set name failed\n");
 	exit(1);
     }
     printf("server configured to use Mach ports\n");
 #endif

     [[NSRunLoop currentRunLoop] run];
 }

 void client(int argc, const char *argv[]) {
     NSPort *sendPort = nil;
     NSConnection *conn;
     id proxyObj;
     long result;
     NSString *hostName = nil;

     if (1 < argc) {
 	hostName = [NSString stringWithCString:argv[1]];
     }

     sendPort = [[NSMachBootstrapServer sharedInstance] 
 portForName:@"TikiTV" host:hostName];
     if (nil == sendPort) {
 	// This will succeed (if host exists), even when there is no server
 	// on the other end, since the connect() is done lazily (arguably wrong),
 	// when first message is sent.
 	sendPort = [[NSSocketPort alloc] initRemoteWithTCPPort:SERVER_PORT 
 host:hostName];
     }
     if (nil == sendPort) {
 	printf("client: could not look up server\n");
 	exit(1);
     }
     NS_DURING
 	conn = [[NSConnection alloc] initWithReceivePort:(NSPort*)
              [[sendPort class] port] sendPort:sendPort];
 	proxyObj = [conn rootProxy];
     NS_HANDLER
 	proxyObj = nil;
     NS_ENDHANDLER
     if (nil == proxyObj) {
 	printf("client: getting proxy failed\n");
 	exit(1);
     }
     [proxyObj setProtocolForProxy:@protocol(ServerProtocol2)];
     printf("client configured to use %s\n", ([sendPort class] == 
 [NSSocketPort self]) ? "sockets" : "Mach ports");

	NSData *data = [proxyObj pictureForStream:0];
	NSLog(@"data is %d bytes", [data length]);

     result = [proxyObj getRandom];
     printf("random #: %ld\n", result);
     result = [proxyObj getRandom];
     printf("random #: %ld\n", result);

     printf("\nset seed\n");
     [proxyObj setRandomSeed:17];
     result = [proxyObj getRandom];
     printf("random #: %ld\n", result);
     result = [proxyObj getRandom];
     printf("random #: %ld\n", result);

     printf("\nset seed\n");
     [proxyObj setRandomSeed:17];
     result = [proxyObj getRandom];
     printf("random #: %ld\n", result);
     result = [proxyObj getRandom];
     printf("random #: %ld\n", result);
	NSLog(@"data %@", [proxyObj getData]);
	int i;
	for(i = 0; i < 0; i++) {
		NSString *s = [proxyObj getString];
	}
	NSLog(@"string %@", [proxyObj getString]);
	int y, f;
	for(f = 0; f < 10; f++) {
	for(y = 0; y < 60; y++) {
	NSData *data = [proxyObj getBigData];
	unsigned char *ptr = [data bytes];
	int x = 0;
	for(i = 0; i < DLEN; i++) {
		ptr[i] = 7;
	}
	}
	NSLog(@"did 60 f");
	}
 }

@interface Client:NSObject
{
}
- (void)threadEntry;
@end
@implementation Client
{
}
- (void)threadEntry {
     id pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"thread entry!!!");
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	client(0, NULL);
     [pool release];
}
@end

 int main(int argc, const char *argv[]) {
     id pool = [[NSAutoreleasePool alloc] init];
	Client *cli = [[Client alloc] init];
     if (0 < argc && 0 == strcmp(argv[0] + strlen(argv[0]) - 6, "server")) {
	//[NSThread detachNewThreadSelector:@selector(threadEntry) toTarget:cli withObject:nil];
 	server(argc, argv);


     } else {
 	client(argc, argv);
     }
     [pool release];
     exit(0);
 }

#import <Foundation/Foundation.h>

#import "GenerateSchema.h"

int main (int argc, const char* argv[]) {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray* arguments = [NSMutableArray arrayWithCapacity:argc];
	
	for(int i=1; i<argc; ++i) {
		[arguments addObject:[NSString stringWithUTF8String:argv[i]]];
	}
	
//	[arguments addObject:@"en"];
	[arguments addObject:@"fr"];
	
	GenerateSchema* command = [[[GenerateSchema alloc] init] autorelease];
	[command execute:arguments];
   
    [pool drain];

    return 0;
}

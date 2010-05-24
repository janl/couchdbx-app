/*
 *  Author: Jan Lehnardt <jan@apache.org>
 *  This is Apache 2.0 licensed free software
 */
#import "CouchDBXApplicationController.h"

@implementation CouchDBXApplicationController

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app
{
  return YES;
}

- (void)windowWillClose:(NSNotification *)aNotification 
{
    [self stop];
}

-(void)awakeFromNib
{
    [browse setEnabled:NO];
	NSLayoutManager *lm;
	lm = [outputView layoutManager];
	[lm setDelegate:self];
	[self launchCouchDB];
}

-(IBAction)start:(id)sender
{
    if([task isRunning]) {
      [self stop];
      return;
    } 
    
    [self launchCouchDB];
}

-(void)stop
{
    NSFileHandle *writer;
    writer = [in fileHandleForWriting];
    [writer writeData:[@"q().\n" dataUsingEncoding:NSASCIIStringEncoding]];
    [writer closeFile];
  
    [browse setEnabled:NO];
    [start setImage:[NSImage imageNamed:@"start.png"]];
    [start setLabel:@"start"];
}

-(void)launchCouchDB
{
    [browse setEnabled:YES];
    [start setImage:[NSImage imageNamed:@"stop.png"]];
    [start setLabel:@"stop"];


	in = [[NSPipe alloc] init];
	out = [[NSPipe alloc] init];
	task = [[NSTask alloc] init];

	NSMutableString *launchPath = [[NSMutableString alloc] init];
	[launchPath appendString:[[NSBundle mainBundle] resourcePath]];
	[launchPath appendString:@"/couchdbx-core"];
	[task setCurrentDirectoryPath:launchPath];

	[launchPath appendString:@"/couchdb/bin/couchdb"];
	[task setLaunchPath:launchPath];
	NSArray *args = [[NSArray alloc] initWithObjects:@"-i", nil];
	[task setArguments:args];
	[task setStandardInput:in];
	[task setStandardOutput:out];

	NSFileHandle *fh = [out fileHandleForReading];
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];

	[nc addObserver:self
					selector:@selector(dataReady:)
							name:NSFileHandleReadCompletionNotification
						 object:fh];
	
	[nc addObserver:self
					selector:@selector(taskTerminated:)
							name:NSTaskDidTerminateNotification
						object:task];

  	[task launch];
  	[outputView setString:@"Starting CouchDB...\n"];
  	[fh readInBackgroundAndNotify];
	sleep(1);
	[self openFuton];
}

-(void)taskTerminated:(NSNotification *)note
{
    [self cleanup];
}

-(void)cleanup
{
    [task release];
    task = nil;
    
    [in release];
    in = nil;
		[out release];
		out = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)openFuton
{
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	NSString *homePage = [info objectForKey:@"HomePage"];
	[webView setTextSizeMultiplier:1.3];
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:homePage]]];
}

-(IBAction)browse:(id)sender
{
	[self openFuton];
    //[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://127.0.0.1:5984/_utils/"]];
}

- (void)appendData:(NSData *)d
{
    NSString *s = [[NSString alloc] initWithData: d
                                        encoding: NSUTF8StringEncoding];
    NSTextStorage *ts = [outputView textStorage];
    [ts replaceCharactersInRange:NSMakeRange([ts length], 0) withString:s];
    [s release];
}

- (void)dataReady:(NSNotification *)n
{
    NSData *d;
    d = [[n userInfo] valueForKey:NSFileHandleNotificationDataItem];
    if ([d length]) {
      [self appendData:d];
    }
    if (task)
      [[out fileHandleForReading] readInBackgroundAndNotify];
}

- (void)layoutManager:(NSLayoutManager *)aLayoutManager didCompleteLayoutForTextContainer:(NSTextContainer *)aTextContainer atEnd:(BOOL)flag
{
	if (flag) {
		NSTextStorage *ts = [outputView textStorage];
		[outputView scrollRangeToVisible:NSMakeRange([ts length], 0)];
	}
}

@end

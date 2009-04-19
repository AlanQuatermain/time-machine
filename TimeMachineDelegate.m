#import "TimeMachineDelegate.h"
#import "MyDocument.h"

@implementation TimeMachineDelegate

- (id) init
{
    if ( [super init] == nil )
        return ( nil );

    _snapshotDocuments = [NSMutableDictionary new];

    return ( self );
}

- (void) dealloc
{
    [_snapshotDocuments release];
    [super dealloc];
}

- (void) awakeFromNib
{
    if ( _snapshotDocuments == nil )
        _snapshotDocuments = [NSMutableDictionary new];

    [AQTimeMachineController timeMachineController].delegate = self;
}

- (BOOL) canEnterTimeMachine
{
    if ( [[[NSRunLoop mainRunLoop] currentMode] isEqualToString: NSModalPanelRunLoopMode] )
        return ( NO );

    // check if there's a *stored* document open at all
    if ( [[NSDocumentController sharedDocumentController] currentDirectory] == nil )
        return ( NO );

    NSDocument * doc = [[NSDocumentController sharedDocumentController] currentDocument];

    // get the main window & check for a sheet
    NSArray * controllers = [doc windowControllers];
    if ( [controllers count] == 0 )
        return ( NO );      // no windows ??

    NSWindowController * ctrl = [controllers objectAtIndex: 0];
    if ( [[ctrl window] attachedSheet] != nil )
        return ( NO );      // sheet attached, must be cancelled first

    // good to go
    return ( YES );
}

- (NSWindowController *) liveDataWindowController
{
    return ( [[_liveDocument windowControllers] objectAtIndex: 0] );
}

- (NSString *) liveDataPath
{
    return ( [[_liveDocument fileURL] path] );
}

- (NSWindowController *) newWindowControllerForPath: (NSString *) path
{
    // create a document, don't show it
    //NSLog( @"Creating new controller for path: %@", path );
    NSError * error = nil;
    MyDocument * newdoc = [[NSDocumentController sharedDocumentController]
                           makeDocumentWithContentsOfURL: [NSURL fileURLWithPath: path]
                                                  ofType: [_liveDocument fileType]
                                                   error: &error];
    if ( newdoc == nil )
    {
        NSLog( @"Failed to create document - %@", error );
        return ( nil );
    }

    // make the window controllers
    [newdoc makeWindowControllers];

    NSArray * controllers = [newdoc windowControllers];
    if ( [controllers count] == 0 )
    {
        NSLog( @"No window controllers in document" );
        return ( nil );
    }

    // store this one so we can delete it later
    [_snapshotDocuments setObject: newdoc forKey: [path stringByStandardizingPath]];

    return ( [controllers objectAtIndex: 0] );
}

- (void) restoreFromURL: (NSURL *) url restoreAll: (BOOL) restoreAll
{
    // at present, let's just assume restoreAll is always set

    // have the main document load the backup document...
    NSError * error = nil;
    [_liveDocument revertToContentsOfURL: url ofType: nil error: &error];

    // and save the new contents
    [_liveDocument saveDocument: nil];
}

- (void) willActivateTimeMachine
{
    // setup current document window controller & path
    _liveDocument = [[NSDocumentController sharedDocumentController] currentDocument];

    // get the main window & check for a sheet
    if ( [[_liveDocument windowControllers] count] == 0 )
        @throw ([NSException exceptionWithName: NSInternalInconsistencyException
                                        reason: @"Time Machine activated with no main document window controller !"
                                      userInfo: nil]);

    // optionally take note of the selected items in the interface, and
    // the value of the search string, and store those
}

- (void) willActivateSnapshotForPath: (NSString *) path
{
    MyDocument * doc = [_snapshotDocuments objectForKey: [path stringByStandardizingPath]];

    // setup the document with any saved searches, selections, etc.
}

- (void) willDeactivateSnapshotForPath: (NSString *) path
{
    MyDocument * doc = [_snapshotDocuments objectForKey: [path stringByStandardizingPath]];

    // again, save the search string and/or selection here
}

- (void) timeMachineWasDismissed
{
    for ( NSString * key in _snapshotDocuments )
    {
        [[_snapshotDocuments objectForKey: key] close];
    }

    [_snapshotDocuments removeAllObjects];

    // perform anything here, such as updating your object model, that
    // would be necessary at this point
}

@end

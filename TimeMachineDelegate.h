#import <Cocoa/Cocoa.h>
#import "AQTimeMachineController.h"
#import "MyDocument.h"

@interface TimeMachineDelegate : NSObject <AQTimeMachineDelegate>
{
    NSDictionary *          _storedSelections;
    NSString *              _searchString;
    NSMutableDictionary *   _snapshotDocuments;

    MyDocument *            _liveDocument;
}

// required protocol
- (BOOL) canEnterTimeMachine;
- (NSWindowController *) liveDataWindowController;
- (NSString *) liveDataPath;
- (NSWindowController *) newWindowControllerForPath: (NSString *) path;
- (void) restoreFromURL: (NSURL *) url restoreAll: (BOOL) restoreAll;

// optional protocol
- (void) willActivateTimeMachine;
- (void) willActivateSnapshotForPath: (NSString *) path;
- (void) willDeactivateSnapshotForPath: (NSString *) path;
- (void) timeMachineWasDismissed;

@end

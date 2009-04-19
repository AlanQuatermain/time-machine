/*
 *  AQTimeMachineController.h
 *  TimeMachine
 *
 *  Created by Alan Quatermain on 1/11/2007.
 *  Copyright (c) 2007 Alan Quatermain. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, provided you include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2007 Alan Quatermain
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by/3.0/
 *
 */

#import "Backup.h"
#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class NSString, NSDictionary, NSMutableDictionary, NSURL, NSWindowController;

// delegates must implement this protocol

@protocol AQTimeMachineDelegate <NSObject>

@required

- (BOOL) canEnterTimeMachine;
- (NSWindowController *) liveDataWindowController;
- (NSString *) liveDataPath;
- (NSWindowController *) newWindowControllerForPath: (NSString *) path;
- (void) restoreFromURL: (NSURL *) url restoreAll: (BOOL) restoreAll;

@optional

- (void) willActivateTimeMachine;
- (void) didActivateTimeMachine;

- (void) willActivateSnapshotForPath: (NSString *) path;
- (void) didActivateSnapshotForPath: (NSString *) path;

- (void) willDeactivateSnapshotForPath: (NSString *) path;
- (void) didDeactivateSnapshotForPath: (NSString *) path;

- (void) showChangedItemsOnlyToggled: (BOOL) showChangedOnly;

- (void) timeMachineWasDismissed;

@end

// for those interested, this is modeled upon Address Book's
// implementation

// this object will handle thumbnail generation for you, but you will
// need to implement the required functions in the protocol above to
// get that functionality.

@interface AQTimeMachineController : NSObject
{
    // Controllers for each snapshot window created, indexed by backup
    // path
    NSMutableDictionary *   _windowControllers;

    // frame of the active window when time machine was activated
    NSRect                  _originalFrame;

    // state of main window when time machine was activated
    BOOL                    _originallyMiniaturized;
    BOOL                    _originallyVisible;

    // working window bounds, provided by Time Machine
    NSRect                  _workingBounds;
    BOOL                    _changedItemsOnly;

    // the delegate, which implements the required logic
    id<AQTimeMachineDelegate> __weak _delegate;

    BOOL                    _allowThumbnailUpdates;
}

// you MUST set a delegate, or else Time Machine activation won't happen
@property(assign) id<AQTimeMachineDelegate> __weak delegate;
@property NSRect workingBounds;
@property BOOL changedItemsOnly;

// use this to fetch the singleton instance
+ (AQTimeMachineController *) timeMachineController;

// these two pass directly on to the delegate
- (BOOL) canEnterTimeMachine;
- (void) restoreFromURL: (NSURL *) url restoreAll: (BOOL) restoreAll;

- (void) setWindowController: (NSWindowController *) controller forPath: (NSString *) path;
- (NSWindowController *) windowControllerForPath: (NSString *) path;
- (NSWindowController *) windowControllerForPath: (NSString *) path createIfNeeded: (BOOL) allowCreate;
- (void) resetWindowControllers;

- (IBAction) browseBackups: (id) sender;

- (void) closeAllTimeMachineWindows;
- (void) dismissTimeMachine;

- (void) updateThumbnailForPath: (NSString *) path;
- (void) updateThumbnailForWindowController: (NSWindowController *) controller path: (NSString *) path;

// this function should be called whenever data changes while in Time
// Machine mode
- (void) invalidateSnapshotImages;

@end

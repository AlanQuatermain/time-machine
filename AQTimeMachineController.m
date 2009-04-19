/*
 *  AQTimeMachineController.m
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

#import "AQTimeMachineController.h"
#import <Cocoa/Cocoa.h>

static AQTimeMachineController * __singleton = nil;

@interface AQTimeMachineController (BackupCallbacks)

- (void) _requestSnapshotImage: (NSURL *) url;
- (void) _activateSnapshot: (NSURL *) url bounds: (NSRect) bounds;
- (void) _deactivateSnapshot: (NSURL *) url;
- (void) _timeMachineRestore: (NSURL *) url unknown2: (void *) unknown2 restoreAll: (BOOL) restoreAll;
- (void) _timeMachineDismissed;
- (void) _showChangedItemsOnlyToggled: (BOOL) newValue;

@end

static void _RequestSnapshotImage( void * token, CFURLRef url )
{
    AQTimeMachineController * tm = (AQTimeMachineController *) token;
    [tm _requestSnapshotImage: (NSURL *) url];
}

static void _ActivateSnapshot( void * token, CFURLRef url, CGRect bounds )
{
    AQTimeMachineController * tm = (AQTimeMachineController *) token;
    [tm _activateSnapshot: (NSURL *) url bounds: *((NSRect*) &bounds)];
}

static void _DeactivateSnapshot( void * token, CFURLRef url )
{
    AQTimeMachineController * tm = (AQTimeMachineController *) token;
    [tm _deactivateSnapshot: (NSURL *) url];
}

static void _TimeMachineRestore( void * token, CFURLRef url, void * unknown2, Boolean restoreAll )
{
    AQTimeMachineController * tm = (AQTimeMachineController *) token;
    [tm _timeMachineRestore: (NSURL *) url unknown2: unknown2 restoreAll: (BOOL) restoreAll];
}

static void _TimeMachineDismissed( void * token )
{
    AQTimeMachineController * tm = (AQTimeMachineController *) token;
    [tm _timeMachineDismissed];
}

static void _ShowChangedItemsOnlyToggled( void * token, Boolean value )
{
    AQTimeMachineController * tm = (AQTimeMachineController *) token;
    [tm _showChangedItemsOnlyToggled: (BOOL) value];
}

static void _StartTimeMachineFromDock( void )
{
    [[AQTimeMachineController timeMachineController] browseBackups: nil];
}

#pragma mark -

@implementation AQTimeMachineController

@synthesize delegate = _delegate;
@synthesize workingBounds = _workingBounds;
@synthesize changedItemsOnly = _changedItemsOnly;

+ (AQTimeMachineController *) timeMachineController
{
    if ( __singleton != nil )
        return ( __singleton );

    @synchronized(self)
    {
        if ( __singleton == nil )
            __singleton = [[self alloc] init];
    }

    return ( __singleton );
}

+ (id) allocWithZone: (NSZone *) zone
{
    id result = __singleton;
    if ( result != nil )
        return ( result );

    @synchronized(self)
    {
        result = __singleton;
        if ( result == nil )
            result = [super allocWithZone: zone];
    }

    return ( result );
}

- (id) retain
{
    return ( self );
}

- (void) release
{
}

- (void) setChangedItemsOnly: (BOOL) flag
{
    @synchronized(self)
    {
        _changedItemsOnly = flag;
    }

    if ( [self.delegate respondsToSelector: @selector(showChangedItemsOnlyToggled:)] )
        [self.delegate showChangedItemsOnlyToggled: flag];

    [self invalidateSnapshotImages];
}

- (void) setDelegate: (id<AQTimeMachineDelegate>) delegate
{
    if ( [delegate conformsToProtocol: @protocol(AQTimeMachineDelegate)] == NO )
        return;

    @synchronized(self)
    {
        _delegate = delegate;
    }
}

- (id) init
{
    if ( [super init] == nil )
        return ( nil );

    _windowControllers = [NSMutableDictionary new];
    [self resetWindowControllers];

    _allowThumbnailUpdates = NO;

    BURegisterStartTimeMachineFromDock( _StartTimeMachineFromDock );

    return ( self );
}

- (void) dealloc
{
    [_windowControllers release];
    [super dealloc];
}

- (BOOL) canEnterTimeMachine
{
    if ( self.delegate == nil )
        return ( NO );

    return ( [self.delegate canEnterTimeMachine] );
}

- (void) restoreFromURL: (NSURL *) url restoreAll: (BOOL) restoreAll
{
    if ( self.delegate == nil )
        return;

    [self.delegate restoreFromURL: url restoreAll: restoreAll];
}

- (void) setWindowController: (NSWindowController *) controller forPath: (NSString *) path
{
    [_windowControllers setObject: controller forKey: [path stringByStandardizingPath]];
}

- (NSWindowController *) windowControllerForPath: (NSString *) path
{
    return ( [self windowControllerForPath: path createIfNeeded: NO] );
}

- (NSWindowController *) windowControllerForPath: (NSString *) path
                                  createIfNeeded: (BOOL) allowCreate
{
    path = [path stringByStandardizingPath];
    NSWindowController * result = [_windowControllers objectForKey: path];

    if ( (result == nil) && (allowCreate) && (self.delegate != nil) )
    {
        result = [self.delegate newWindowControllerForPath: path];
        if ( result == nil )
        {
            NSLog( @"There was an error creating a window controller for backup path %@", path );
            return ( nil );
        }

        [_windowControllers setObject: result forKey: path];
    }

    if ( (result != nil) && (isgreater(self.workingBounds.size.width, 0.0f)) )
        [[result window] setFrame: self.workingBounds display: YES];

    return ( result );
}

- (void) resetWindowControllers
{
    [_windowControllers removeAllObjects];

    if ( self.delegate == nil )
        return;

    [_windowControllers setObject: [self.delegate liveDataWindowController]
                           forKey: [[self.delegate liveDataPath] stringByStandardizingPath]];
}

- (IBAction) browseBackups: (id) sender
{
    if ( [self canEnterTimeMachine] == NO )
        return;

    if ( [self.delegate respondsToSelector: @selector(willActivateTimeMachine)] )
        [self.delegate willActivateTimeMachine];

    NSWindowController * mainctrl = [self.delegate liveDataWindowController];
    NSWindow * window = [mainctrl window];

    _originallyVisible = [window isVisible];
    _originallyMiniaturized = [window isMiniaturized];
    _originalFrame = [window frame];

    if ( _originallyMiniaturized )
        [mainctrl showWindow: self];
    else
        [window makeKeyAndOrderFront: self];

    CFURLRef url = CFURLCreateWithFileSystemPath( NULL, (CFStringRef) [[self.delegate liveDataPath] stringByStandardizingPath],
        kCFURLPOSIXPathStyle, FALSE );

    // register all the callbacks
    BURegisterRequestSnapshotImage( self, _RequestSnapshotImage );
    BURegisterActivateSnapshot( self, _ActivateSnapshot );
    BURegisterDeactivateSnapshot( self, _DeactivateSnapshot );
    BURegisterTimeMachineDismissed( self, _TimeMachineDismissed );
    BURegisterTimeMachineRestore( self, _TimeMachineRestore );
    BURegisterShowChangedItemsOnlyToggled( self, _ShowChangedItemsOnlyToggled );

    BUStartTimeMachine( [window windowNumber], url, 3 );

    if ( [self.delegate respondsToSelector: @selector(didActivateTimeMachine)] )
        [self.delegate didActivateTimeMachine];

    if ( url != NULL )
        CFRelease( url );

    _allowThumbnailUpdates = YES;
}

- (void) closeAllTimeMachineWindows
{
    NSArray * allControllers = [_windowControllers allValues];
    NSWindowController * mainCtrl = [self.delegate liveDataWindowController];
    NSWindow * mainWindow = [mainCtrl window];

    for ( NSWindowController * ctrl in allControllers )
    {
        if ( ctrl != mainCtrl )
            [ctrl close];
    }

    if ( _originallyMiniaturized )
        [mainWindow miniaturize: self];
    else if ( _originallyVisible == NO )
        [mainWindow close];
    else
        [mainWindow makeKeyAndOrderFront: self];

    [_windowControllers removeAllObjects];
}

- (void) dismissTimeMachine
{
    BUTimeMachineAction( 1 );
    _allowThumbnailUpdates = NO;
}

- (void) updateThumbnailForPath: (NSString *) path
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];

    NSWindowController * ctrl = [self windowControllerForPath: path createIfNeeded: YES];
    [[ctrl window] setFrame: self.workingBounds display: YES];

    [self updateThumbnailForWindowController: ctrl path: path];

    [pool drain];
}

- (void) updateThumbnailForWindowController: (NSWindowController *) controller path: (NSString *) path
{
    if ( _allowThumbnailUpdates == NO )
        return;

    if ( controller == nil )
        return;

    CFURLRef url = CFURLCreateWithFileSystemPath( NULL, (CFStringRef) [path stringByStandardizingPath],
        kCFURLPOSIXPathStyle, FALSE );

    if ( url == NULL )
        return;

    NSWindow * window = [controller window];
    BOOL visible = [window isVisible];

    if ( !visible )
        [window orderBack: self];

    BUUpdateSnapshotImage( [window windowNumber], url );

    if ( visible )
        [window display];
    else
        [window orderOut: self];

    CFRelease( url );
}

- (void) invalidateSnapshotImages
{
    BUInvalidateAllSnapshotImages( );
}

@end

@implementation AQTimeMachineController (BackupCallbacks)

- (void) _requestSnapshotImage: (NSURL *) url
{
    self.workingBounds = [[[self.delegate liveDataWindowController] window] frame];
    [self updateThumbnailForPath: [url path]];
}

- (void) _activateSnapshot: (NSURL *) url bounds: (NSRect) bounds
{
    NSString * path = [[url path] stringByStandardizingPath];

    self.workingBounds = bounds;
    NSWindowController * ctrl = [self windowControllerForPath: path createIfNeeded: YES];
    NSWindow * window = [ctrl window];
    [window orderFront: self];
    [window makeKeyWindow];
    [self updateThumbnailForWindowController: ctrl path: path];

    if ( [self.delegate respondsToSelector: @selector(willActivateSnapshotForPath:)] )
        [self.delegate willActivateSnapshotForPath: path];

    BUActivatedSnapshot( [window windowNumber], (CFURLRef) url );

    if ( [self.delegate respondsToSelector: @selector(didActivateSnapshotForPath:)] )
        [self.delegate didActivateSnapshotForPath: path];
}

- (void) _deactivateSnapshot: (NSURL *) url
{
    NSString * path = [[url path] stringByStandardizingPath];
    NSWindowController * ctrl = [self windowControllerForPath: path];

    if ( [self.delegate respondsToSelector: @selector(willDeactivateSnapshotForPath:)] )
        [self.delegate willDeactivateSnapshotForPath: path];

    //NSLog( @"Closing window controller %@", ctrl );
    [ctrl close];

    BUDeactivatedSnapshot( [[ctrl window] windowNumber], (CFURLRef) url );

    if ( [self.delegate respondsToSelector: @selector(didDeactivateSnapshotForPath:)] )
        [self.delegate didDeactivateSnapshotForPath: path];
}

- (void) _timeMachineRestore: (NSURL *) url unknown2: (void *) unknown2 restoreAll: (BOOL) restoreAll
{
    [self restoreFromURL: url restoreAll: restoreAll];
}

- (void) _timeMachineDismissed
{
    NSBeep( );
    BURegisterRequestSnapshotImage( self, NULL );
    BURegisterActivateSnapshot( self, NULL );
    BURegisterDeactivateSnapshot( self, NULL );
    BURegisterTimeMachineDismissed( self, NULL );
    BURegisterTimeMachineRestore( self, NULL );
    BURegisterShowChangedItemsOnlyToggled( self, NULL );

    [self closeAllTimeMachineWindows];
    self.workingBounds = NSZeroRect;

    if ( [self.delegate respondsToSelector: @selector(timeMachineWasDismissed)] )
        [self.delegate timeMachineWasDismissed];
}

- (void) _showChangedItemsOnlyToggled: (BOOL) newValue
{
    self.changedItemsOnly = newValue;
}

@end

/*
 *  Backup.h
 *  AQBackupController
 *
 *  Created by Alan Quatermain on 31/10/2007.
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

/*!
 * @header Backup
 * The private Backup API described here is used by applications
 * including Address Book, Mail, iPhoto, and the Finder to provide
 * information for the Time Machine user interface. The API itself
 * relies on callbacks routines registered by an interested
 * application, which then needs to provide windows and thumbnails for
 * the Time Machine UI to display.
 *
 * An application wishing to handle Time Machine events within its own
 * UI needs to first call BURegisterStartTimeMachineFromDock(),
 * providing a callback function there. When the dock icon is clicked,
 * this callback is called, at which point the application may register
 * for any other callbacks in which it has an interest.
 */

#ifndef __BACKUP_INTERNAL_H__
#define __BACKUP_INTERNAL_H__

#include <CoreFoundation/CFURL.h>
#include <ApplicationServices/ApplicationServices.h>    // for CGRect

#ifdef __cplusplus
extern "C" {
#endif

// the following are all C functions exported by the Backup framework,
// located in /System/Library/PrivateFrameworks.

enum
{
    BUActionDismiss     = 1,
    BUActionStart       = 2
};
typedef unsigned int BUAction;

/*!
 * @typedef BUStartTimeMachineCallBack
 * Type of the callback function used to notify an application of Time
 * Machine invocation.
 */
typedef void (*BUStartTimeMachineCallBack)( void );

/*!
 * @typedef BUShowChangedItemsOnlyToggledCallBack
 * Type of the callback used to notify a change of the changedItemsOnly
 * flag.
 * @param token A token value provided upon registration of the
 * callback.
 * @param changedOnly The new value of the changedItemsOnly flag.
 */
typedef void (*BUShowChangedItemsOnlyToggledCallBack)( void * token, Boolean changedOnly );

/*!
 * @typedef BUTimeMachineDismissedCallBack
 * Type of the callback used to notify an app that the TimeMachine
 * interface has been dismissed.
 * @param token A token value provided upon registration of the
 * callback.
 */
typedef void (*BUTimeMachineDismissedCallBack)( void * token );

/*!
 * @typedef BUTimeMachineRestoreCallBack
 * Type of the callback used to request that a restore operation take
 * place.
 * @param token A token value provided upon registration of the
 * callback.
 * @param url A URL to the data to restore.
 * @param unknown Unknown.
 * @param restoreAll TRUE if all data is to be restored, FALSE if only
 * a single item is to be restored (within the application's document,
 * for instance).
 */
typedef void (*BUTimeMachineRestoreCallBack)( void * token, CFURLRef backupURL, void * unknown, Boolean restoreAll );

/*!
 * @typedef BUActivateSnapshotCallBack
 * Type of the callback used to request that a new snapshot window
 * become active for user input.
 * @param token A token value provided upon registration of the
 * callback.
 * @param backupURL A backup file URL corresponding to the chosen
 * snapshot.
 * @param workingBounds Bounds of the snapshot window, once active.
 * @discussion
 * Upon receipt of this callback, the caller should update its
 * TimeMachine windows and/or controllers (creating one if necessary)
 * using the given working bounds. Once the window has been setup and
 * the application has made any necessary alterations (setting a search
 * string for example) it should call @link BUActivatedSnapshot
 * BUActivatedSnapshot @/link passing the snapshot window's window
 * number and the given backup URL.
 */
typedef void (*BUActivateSnapshotCallBack)( void * token, CFURLRef backupURL, CGRect workingBounds );

/*!
 * @typedef BUDeactivateSnapshotCallBack
 * Type of the callback used to request that an active snapshot window
 * be deactivated.
 * @param token A token value provided upon registration of the
 * callback.
 * @param backupURL A backup file URL corresponding to the chosen
 * snapshot.
 * @discussion
 * Upon receipt of this callback, the caller should close any active
 * window (unless this is the 'real' window for the current live data)
 * and call @link BUDeactivatedSnapshot BUDeactivatedSnapshot @/link,
 * passing in the closing window's window number and the given backup
 * URL.
 */
typedef void (*BUDeactivateSnapshotCallBack)( void * token, CFURLRef backupURL );

/*!
 * @typedef BURequestSnapshotImageCallBack
 * Type of the callback used to request a new image for an inactive
 * snapshot 'window'.
 * @param token A token value provided upon registration of the
 * callback.
 * @param backupURL A backup file URL corresponding to the chosen
 * snapshot.
 * @discussion
 * This function is called to request that the application provide an
 * image to be used for an inactive snapshot. The resulting image will
 * be used as one of the 'windows' further back in time in the Time
 * Machine user interface.
 *
 * The image is supplied to Time Machine by calling
 * @link BUUpdateSnapshotImage BUUpdateSnapshotImage @/link and passing
 * in a window number and backup URL pair. The Backup framework will
 * then automatically generate an image from the window's contents.
 */
typedef void (*BURequestSnapshotImageCallBack)( void * token, CFURLRef backupURL );

#pragma mark -

/*!
 * @function BURegisterStartTimeMachineFromDock
 * @param callback The callback to install.
 * The supplied function will be called when the user clicks on the
 * Time Machine icon in the dock while the calling application is
 * active.
 */
void BURegisterStartTimeMachineFromDock( BUStartTimeMachineCallBack callback );

/*!
 * @function BURegisterRequestSnapshotImage
 * @param token A token provided to callback invocations.
 * @param callback The callback to install.
 * The supplied function will be called when the Time Machine engine
 * needs to display an image for a past backup snapshot. The image
 * should be passed back to the Backup engine by calling
 * @link BUUpdateSnapshotImage BUUpdateSnapshotImage @/link.
 */
void BURegisterRequestSnapshotImage( void * token, BURequestSnapshotImageCallBack callback );

void BURegisterActivateSnapshot( void * token, BUActivateSnapshotCallBack callback );
void BURegisterDeactivateSnapshot( void * token, BUDeactivateSnapshotCallBack callback );

void BURegisterTimeMachineDismissed( void * token, BUTimeMachineDismissedCallBack callback );
void BURegisterTimeMachineRestore( void * token, BUTimeMachineRestoreCallBack callback );

void BURegisterShowChangedItemsOnlyToggled( void * token, BUShowChangedItemsOnlyToggledCallBack callback );

#pragma mark -

void BUStartTimeMachine( int windowNumber, CFURLRef urlForWindow, BUAction flags );

void BUTimeMachineAction( BUAction action );

void BUActivatedSnapshot( int windowNumber, CFURLRef url );
void BUDeactivatedSnapshot( int windowNumber, CFURLRef url );

void BUUpdateThumbnail( CFURLRef url, CGImageRef image );
void BUUpdateThumbnailFromWindow( CFURLRef url, int windowNumber );

void BUUpdateGenericSnapshotImage( int windowNumber );
void BUUpdateSnapshotImage( int windowNumber, CFURLRef url );

#ifdef __cplusplus
};
#endif

#endif  /* __BACKUP_INTERNAL_H__ */
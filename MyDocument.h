//
//  MyDocument.h
//  TimeMachineTester
//
//  Created by Jim Dovey on 01/11/07.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MyDocument : NSPersistentDocument
{
    BOOL    inTimeMachine;
}

@property BOOL inTimeMachine;

@end

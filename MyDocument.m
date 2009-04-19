//
//  MyDocument.m
//  TimeMachineTester
//
//  Created by Jim Dovey on 01/11/07.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

@synthesize inTimeMachine;

- (id)init 
{
    self = [super init];
    if (self != nil) {
        // initialization code
    }
    return self;
}

- (NSString *)windowNibName 
{
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
    [super windowControllerDidLoadNib:windowController];
    // user interface preparation code
}

@end

//
//  CommitMessageMO.m
//  TimeMachineTester
//
//  Created by Jim Dovey on 01/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CommitMessageMO.h"


@implementation CommitMessageMO

- (void) awakeFromInsert
{
	[self setValue: [NSDate date] forKey: @"creationDate"];
}

@end

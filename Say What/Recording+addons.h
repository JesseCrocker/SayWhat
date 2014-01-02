//
//  Recording+addons.h
//  Say What
//
//  Created by Jesse Crocker on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Recording.h"

@interface Recording (addons)
-(void)deleteFile;
-(NSURL *)url;
-(NSString *)filenameForExport;

@end

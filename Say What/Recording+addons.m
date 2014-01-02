//
//  Recording+addons.m
//  Say What
//
//  Created by Jesse Crocker on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Recording+addons.h"

@implementation Recording (addons)
-(void)deleteFile{
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSError *error;
    if(![filemanager removeItemAtURL:self.url error:&error]){
        NSLog(@"error deleteing file: %@", [error localizedDescription]);
    }
}
-(NSURL *)url{
    if(self.path == nil)
        return nil;
    return [NSURL fileURLWithPath:self.path];
}

-(NSString *)filenameForExport{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd-HH:mm";
    NSString *filename = [NSString stringWithFormat:@"%@-SayWhat.m4a", [dateFormatter stringFromDate:self.date]];
    return filename;
}
@end

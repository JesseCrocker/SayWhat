//
//  savedRecordingCell.h
//  Say What
//
//  Created by Jesse Crocker on 6/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Recording.h"

@interface savedRecordingCell : UITableViewCell <UITextFieldDelegate>


@property (nonatomic, strong) IBOutlet UITextField *nameField;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UILabel *durationLabel;
@end

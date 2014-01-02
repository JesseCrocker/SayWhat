//
//  savedSoundsViewController.m
//  Say What
//
//  Created by Jesse Crocker on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "savedSoundsViewController.h"
#import "Recording.h"
#import "AppDelegate.h"
#import "savedRecordingCell.h"

@interface savedSoundsViewController (){
    NSFetchedResultsController *fetchedResultsController;
    NSManagedObjectContext *managedObjectContext;
    NSDateFormatter *dateFormatter;
    NSIndexPath *editingIndexPath;
    NSIndexPath *selectedIndexPath;
}

@end

@implementation savedSoundsViewController
@synthesize tableView = _tableView;
@synthesize playerView = _playerView;
@synthesize playerViewContainer = _playerViewContainer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    [self setupFetchedResultsController];
    NSError *error = nil;
    if(![fetchedResultsController performFetch:&error]){
        NSLog(@"%@", [error localizedDescription]);
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self setupPlayerView];
        [self registerForKeyboardNotifications];
    }
}

- (void)viewDidUnload
{
    fetchedResultsController.delegate = nil;
    fetchedResultsController = nil;
    [self setTableView:nil];
    [self setPlayerView:nil];
    [self setPlayerViewContainer:nil];
    [super viewDidUnload];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedPlayer.playerView = self.playerView;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedPlayer.playerView = nil;
    }
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


-(void)setupPlayerView{
    NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"sayWhatPlayerView_iPhone" owner:self options:nil];
    self.playerView = (sayWhatPlayerView *)[subviewArray objectAtIndex:0];
    self.playerView.closerDelegate = self;
    [self.playerView setup];
    [self.playerViewContainer addSubview:self.playerView];
}

#pragma mark - fetched results controller
-(void)setupFetchedResultsController{
    managedObjectContext = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Recording" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:@"date" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    [fetchRequest setFetchBatchSize:20];
    
    fetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:@"Root"];
    fetchedResultsController.delegate = self;
}
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray
                                                    arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray
                                                    arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    id  sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"recording cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [managedObjectContext deleteObject:[fetchedResultsController objectAtIndexPath:indexPath]];
    }
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return UITableViewCellEditingStyleDelete;
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Recording *thisRecording = [fetchedResultsController objectAtIndexPath:indexPath];
    savedRecordingCell *recordingCell = (savedRecordingCell *)cell;
    recordingCell.dateLabel.text = [dateFormatter stringFromDate:thisRecording.date];
    recordingCell.nameField.text = thisRecording.name;
    recordingCell.nameField.delegate = self;
    if(thisRecording.length && thisRecording.length.intValue > 0){
        int duration = thisRecording.length.intValue;
        recordingCell.durationLabel.text = [NSString stringWithFormat:@"%i:%02i", duration/60, duration%60];
    }else{
        recordingCell.durationLabel.text = @"";
    }
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //[tableView deselectRowAtIndexPath:indexPath animated:YES];
    Recording *thisRecording = [fetchedResultsController objectAtIndexPath:indexPath];
#ifdef DEBUG
    NSLog(@"recording selected: %@", thisRecording);
#endif
    [((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedPlayer setRecordingByID:thisRecording.objectID];
    selectedIndexPath = indexPath;
    [self showPlayer];
}

#pragma mark - textfiled delegate
-(void)textFieldDidBeginEditing:(UITextField *)textField{
    UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
    if([cell isKindOfClass:[UITableViewCell class]])
        editingIndexPath = [self.tableView indexPathForCell:cell];
    else {
        NSLog(@"not a cell");
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if(!editingIndexPath){
        NSLog(@"textfield did end, but editing index path is nil");
        return;
    }
    Recording *rec = [fetchedResultsController objectAtIndexPath:editingIndexPath];
    rec.name = textField.text;
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] saveContext];
    editingIndexPath = nil;
}

#pragma mark -
-(void)showPlayer{
    if(self.playerViewContainer.hidden == NO)
        return;
    CGRect tableFrame = self.tableView.frame;
    tableFrame.size.height -= self.playerViewContainer.frame.size.height;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    self.playerViewContainer.hidden = NO;
    self.tableView.frame = tableFrame;
    [UIView commitAnimations];
    
    [self.tableView scrollToRowAtIndexPath:selectedIndexPath
                          atScrollPosition:UITableViewScrollPositionMiddle 
                                  animated:YES];
}

-(void)hidePlayer{
    if(self.playerViewContainer.hidden)
        return;
    CGRect tableFrame = self.tableView.frame;
    tableFrame.size.height += self.playerViewContainer.frame.size.height;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    self.playerViewContainer.hidden = YES;
    self.tableView.frame = tableFrame;
    [UIView commitAnimations];
}

- (void)registerForKeyboardNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

-(CGRect)rectSwap:(CGRect)rect{
	CGRect newRect;
	newRect.origin.x = rect.origin.y;
	newRect.origin.y = rect.origin.x;
	newRect.size.width = rect.size.height;
	newRect.size.height = rect.size.width;
	return newRect;
}

- (void)keyboardWasShown:(NSNotification*)aNotification{
#ifdef DEBUG
    NSLog(@"recieved keyboard was shown notification");
#endif      
    NSDictionary* userInfo = [aNotification userInfo];
    
    // we don't use SDK constants here to be universally compatible with all SDKs ≥ 3.0
    NSValue* keyboardFrameValue = [userInfo objectForKey:@"UIKeyboardBoundsUserInfoKey"];
    if (!keyboardFrameValue) {
        keyboardFrameValue = [userInfo objectForKey:@"UIKeyboardFrameEndUserInfoKey"];
    }
    
    // Reduce the tableView height by the part of the keyboard that actually covers the tableView
    CGRect windowRect = [[UIApplication sharedApplication] keyWindow].bounds;
    if (UIInterfaceOrientationLandscapeLeft == self.interfaceOrientation ||UIInterfaceOrientationLandscapeRight == self.interfaceOrientation ) {
        windowRect = [self rectSwap:windowRect];
    }
    CGRect viewRectAbsolute = [self.tableView convertRect:self.tableView.bounds toView:[[UIApplication sharedApplication] keyWindow]];
    if (UIInterfaceOrientationLandscapeLeft == self.interfaceOrientation ||UIInterfaceOrientationLandscapeRight == self.interfaceOrientation ) {
        viewRectAbsolute = [self rectSwap:viewRectAbsolute];;
    }
    CGRect frame = self.tableView.frame;
    frame.size.height -= [keyboardFrameValue CGRectValue].size.height - CGRectGetMaxY(windowRect) + CGRectGetMaxY(viewRectAbsolute);
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    self.tableView.frame = frame;
    [UIView commitAnimations];
    
    [self.tableView scrollToRowAtIndexPath:editingIndexPath
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:YES];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification{
#ifdef DEBUG
    NSLog(@"recieved keyboard will be hidden notification");
#endif
    
    CGRect newFrame = CGRectMake(0, 0, self.tableView.frame.size.width, self.view.frame.size.height);
    if(self.playerViewContainer.hidden == NO)
        newFrame.size.height -= 150;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    self.tableView.frame = newFrame;
    [UIView commitAnimations];
}

@end

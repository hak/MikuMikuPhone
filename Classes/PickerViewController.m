    //
//  PickerViewController.m
//  MikuMikuPhone
//
//  Created by hakuroum on 2/23/11.
//  Copyright 2011 hakuroum@gmail.com. All rights reserved.
//

#import "MikuMikuPhoneAppDelegate.h"
#import "PickerViewController.h"

@implementation PickerViewController

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	MikuMikuPhoneAppDelegate* delegate = (MikuMikuPhoneAppDelegate*)[UIApplication sharedApplication].delegate;

    [super viewDidLoad];
	[pickerView selectRow:[delegate getSelection]
			  inComponent:0
				 animated:false];
}


//PickerViewController.m
- (void) cancelPressed:(id)item
{
	MikuMikuPhoneAppDelegate* delegate = (MikuMikuPhoneAppDelegate*)[UIApplication sharedApplication].delegate;
	[delegate hideModal:self.view];
}

- (void) donePressed:(id)item
{
	MikuMikuPhoneAppDelegate* delegate = (MikuMikuPhoneAppDelegate*)[UIApplication sharedApplication].delegate;
	
	int32_t i = [pickerView selectedRowInComponent:0];
	[delegate picked:i ];
	[delegate hideModal:self.view];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
	MikuMikuPhoneAppDelegate* delegate = (MikuMikuPhoneAppDelegate*)[UIApplication sharedApplication].delegate;
	return [[delegate getPickerItems] count];
}


- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	MikuMikuPhoneAppDelegate* delegate = (MikuMikuPhoneAppDelegate*)[UIApplication sharedApplication].delegate;
	return [[delegate getPickerItems] objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	
//	NSLog(@"Selected Color: %@. Index of selected color: %i", [arrayColors objectAtIndex:row], row);
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

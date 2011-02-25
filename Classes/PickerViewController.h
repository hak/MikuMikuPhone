//
//  PickerViewController.h
//  MikuMikuPhone
//
//  Created by hakuroum on 2/23/11.
//  Copyright 2011 hakuroum@gmail.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PickerViewController : UIViewController< UIPickerViewDelegate > {
	IBOutlet UIPickerView* pickerView;
}
- (IBAction)cancelPressed:(id)item;
- (IBAction)donePressed:(id)item;

@end

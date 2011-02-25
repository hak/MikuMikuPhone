//
//  MikuMikuPhoneAppDelegate.h
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PickerViewController.h"

@class EAGLView;

@interface MikuMikuPhoneAppDelegate : NSObject <UIApplicationDelegate, UITabBarDelegate> {
    UIWindow *window;
    EAGLView *glView;
	IBOutlet UITabBar *_tabBar;
	IBOutlet UIViewController* _viewCtrl;
	PickerViewController* _pickerViewCtrl;
	NSMutableArray* _motionFiles;
	NSMutableArray* _modelFiles;
	
	NSString* _strModelFile;
	NSString* _strMotionFile;
	int32_t _iPickerMode;
	int32_t _iCurrentSelection[ 2 ];
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;
@property (nonatomic, retain) NSMutableArray* motionFiles;
@property (nonatomic, retain) NSMutableArray* modelFiles;

- (void) hideModal:(UIView*) modalView;
- (NSArray*) getPickerItems;
- (void) picked:(int32_t)iIndex;
- (int32_t) getSelection;

@end


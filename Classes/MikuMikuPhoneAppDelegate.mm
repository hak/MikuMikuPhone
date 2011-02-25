//
//  MikuMikuPhoneAppDelegate.m
//  MikuMikuPhone
//
//  Created by hakuroum on 1/14/11.
//  Copyright 2011 hakuroum@gmail.com . All rights reserved.
//

#import "MikuMikuPhoneAppDelegate.h"
#import "PickerViewController.h"
#import "EAGLView.h"
#import "pmdReader.h"

@implementation MikuMikuPhoneAppDelegate

@synthesize window;
@synthesize glView;
@synthesize motionFiles = _motionFiles;
@synthesize modelFiles = _modelFiles;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions   
{		
    [glView startAnimation];
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [glView stopAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* doc = [paths objectAtIndex:0];
	NSFileManager* fm = [NSFileManager defaultManager];

	NSArray* files = [fm contentsOfDirectoryAtPath:doc error:nil];
	
	if( _motionFiles == nil )
		_motionFiles = [[NSMutableArray alloc] init];
	if( _modelFiles == nil )
		_modelFiles = [[NSMutableArray alloc] init];

	[_modelFiles removeAllObjects];
	[_motionFiles removeAllObjects];
	
	for( NSString* file in files )
	{
		if( [[file lowercaseString] hasSuffix:@".pmd" ])
		{
			[_modelFiles addObject:file];
		}
		else if( [[file lowercaseString] hasSuffix:@".vmd" ])
		{
			[_motionFiles addObject:file];
		}
	}
	
	_strModelFile = @"初音ミクVer2.pmd";
	_strMotionFile = @"恋VOCALOID.vmd";
	_iCurrentSelection[ 0 ] = -1;
	_iCurrentSelection[ 1 ] = -1;
	
	//		NSString* strFile = [[NSBundle mainBundle] pathForResource:@"初音ミク" ofType:@"pmd"];
	for( int32_t i = 0; i < [_modelFiles count]; ++i )
	{
		if( [_strModelFile compare:[_modelFiles objectAtIndex:i]] == 0 )
		{
			_iCurrentSelection[ 0 ] = i;
			break;
		}
	}
	for( int32_t i = 0; i < [_motionFiles count]; ++i )
	{
		if( [_strMotionFile compare:[_motionFiles objectAtIndex:i]] == 0 )
		{
			_iCurrentSelection[ 1 ] = i;
			break;
		}
	}

	[self picked:_iCurrentSelection[ _iPickerMode ]];
	//	[glView.renderer load:strFile motion:strMotionFile];
	

    [glView startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [glView stopAnimation];
}

- (void)dealloc
{
	[_pickerViewCtrl release];
    [window release];
    [glView release];
	[_modelFiles release];
	[_motionFiles release];

    [super dealloc];
}

#pragma mark tabBar
- (void) showModal:(UIView*) modalView
{
    CGSize offSize = [UIScreen mainScreen].bounds.size;
	CGPoint middleCenter = CGPointMake( offSize.width / 2,
									   offSize.height - modalView.bounds.size.height / 2 );
	
    CGPoint offScreenCenter = CGPointMake(offSize.width / 2.0,
										  offSize.height + modalView.bounds.size.height / 2);
    modalView.center = offScreenCenter;
	
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5]; // animation duration in seconds
    modalView.center = middleCenter;
    [UIView commitAnimations];
}	
	
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    if ([finished boolValue])
	{
        [_pickerViewCtrl.view removeFromSuperview];
		[glView startAnimation];
	}
}

- (void) hideModal:(UIView*) modalView
{
    CGSize offSize = [UIScreen mainScreen].bounds.size;
    CGPoint offScreenCenter = CGPointMake(offSize.width / 2.0,
										  offSize.height + modalView.bounds.size.height / 2);
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5]; // animation duration in seconds
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];

    modalView.center = offScreenCenter;
    [UIView commitAnimations];
}	


- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
	_iPickerMode = item.tag;

    [glView stopAnimation];
	
	if( _pickerViewCtrl != nil )
		[_pickerViewCtrl release];
	
	_pickerViewCtrl = [[PickerViewController alloc] init];
	[glView addSubview:_pickerViewCtrl.view];
	[_pickerViewCtrl.view sizeToFit];
	
	[self showModal:_pickerViewCtrl.view];

}

- (NSArray*) getPickerItems
{
	switch (_iPickerMode)
	{
		case 0:
			return _modelFiles;
		default:
			return _motionFiles;
	}
}

- (void) picked:(int32_t)i
{
	if( i >= 0 )
	{
		switch (_iPickerMode)
		{
			case 0:
				_strModelFile = [_modelFiles objectAtIndex:i ];
				break;
			default:
				_strMotionFile = [_motionFiles objectAtIndex:i ];
				break;
		}
		_iCurrentSelection[ _iPickerMode ] = i;
	}
		
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* doc = [paths objectAtIndex:0];

	//NSFileManager* fm = [NSFileManager defaultManager];
	//NSArray* files = [fm contentsOfDirectoryAtPath:doc error:nil];
	
	
	//		NSString* strFile = [[NSBundle mainBundle] pathForResource:@"初音ミク" ofType:@"pmd"];
	NSString* strFile = nil;
	if( _strModelFile )
	{
		strFile = [NSString stringWithFormat:@"%@/%@", doc, _strModelFile];
	}
	NSString* strMotionFile = nil;
	if( _strMotionFile )
	{
		strMotionFile = [NSString stringWithFormat:@"%@/%@", doc, _strMotionFile];
	}
	[glView.renderer load:strFile
				   motion:strMotionFile];

}

- (int32_t) getSelection
{
	return _iCurrentSelection[ _iPickerMode ];
}

@end

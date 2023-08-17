/**
 * File              : AppDelegate.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 17.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "AppDelegate.h"
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#include "RootViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];	
	//if ([[NSUserDefaults standardUserDefaults] valueForKey:@"launchBool"]){
		//[self handleWithURL:self.url onWindow:self.window];
	//} else {
		RootViewController *vc = 
				[[RootViewController alloc]initWithStyle:UITableViewStyleGrouped];
		UINavigationController *nc = 
			[[UINavigationController alloc]initWithRootViewController:vc];
		[self.window setRootViewController:nc];
	//}	
	[self.window makeKeyAndVisible];	
	
	return true;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	if ([url.host isEqualToString:@"authorize"]){
		NSString *fragment = url.fragment;
		NSArray *array = [fragment componentsSeparatedByString:@"&"];
		for (NSString *item in array) {
			NSArray *pair = [item componentsSeparatedByString:@"="];
			NSString *key = [pair objectAtIndex:0];
			NSString *value = [pair objectAtIndex:1];
			[[NSUserDefaults standardUserDefaults]setValue:value forKey:key];
		}
		UIAlertView *alert = 
					[[UIAlertView alloc]initWithTitle:@"response" 
					message:fragment
					delegate:nil 
					cancelButtonTitle:@"Закрыть" 
					otherButtonTitles:nil];
		[alert show];
	}
	return true;
}

@end
// vim:ft=objc


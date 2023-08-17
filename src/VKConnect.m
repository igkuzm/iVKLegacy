/**
 * File              : VKConnect.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 17.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "VKConnect.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#include "cVK.h"

#define CLIENT_ID "51726951"
#define CLIENT_SECRET "GA4ch1qflMIt23C1FXZn"

@implementation VKConnect

- (void)login
{
	uint32_t access_rights =
		AR_NOTIFY 
  | AR_FRIENDS     
  | AR_PHOTOS      
  | AR_AUDIO       
  | AR_VIDEO       
  | AR_STORIES     
  | AR_PAGES       
  | AR_MENU        
  | AR_STATUS      
  | AR_NOTES       
//  | AR_MESSAGES    
  | AR_WALL        
  | AR_ADS         
  | AR_OFFLINE     
  | AR_DOCS        
  | AR_GROUPS      
  | AR_NOTIFICATION
  | AR_STATS       
  | AR_EMAIL       
  | AR_MARKET      
  | AR_PHONE_NUMBER
	;

	char *urlstr = c_vk_auth_url(CLIENT_ID, access_rights);
	if (urlstr){
		NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:urlstr]];
		[[UIApplication sharedApplication]openURL:url];
	} else {
		NSLog(@"Can't get  VK auth URL");
		UIAlertView *alert = 
			[[UIAlertView alloc]initWithTitle:@"error" 
			message:@"Can't get  VK auth URL" 
			delegate:nil 
			cancelButtonTitle:@"Закрыть" 
			otherButtonTitles:nil];
		[alert show];
	}
}
@end

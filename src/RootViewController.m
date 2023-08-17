/**
 * File              : RootViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 16.08.2023
 * Last Modified Date: 17.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "RootViewController.h"
#include "VKConnect.h"
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import "VKFeedViewController.h"

@implementation RootViewController

-(void)loadItems{
	if ([[NSUserDefaults standardUserDefaults]valueForKey:@"access_token"]){
		self.menuItems = @[
			@"Страница",
			@"Новости",
			@"Ответы",
			@"Сообщения",
			@"Друзья",
			@"Группы",
			@"Фоторгафии",
			@"Видеозаписи",
			@"Игры",
			@"Закладки",
			@"Настройки",
		];
	}else{
		self.menuItems = @[
			@"Login"
		];
	}
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
	[self loadItems];
}

- (void)viewDidLoad {
	// make menu
	[self loadItems];

	// start vk feed
	VKFeedViewController *vc = 
			[[VKFeedViewController alloc]init];
	[self.navigationController pushViewController:vc animated:false];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.menuItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil){
		cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault
						reuseIdentifier: @"cell"];
	}
	[cell.textLabel setText:[self.menuItems objectAtIndex:indexPath.item]];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.menuItems.count < 2){
		// start auth
		VKConnect *vc = [[VKConnect alloc]init];
		[vc login];
		return;
	}
	if (indexPath.item == 1){
		VKFeedViewController *vc = 
					[[VKFeedViewController alloc]init];
		[self.navigationController pushViewController:vc animated:true];
	}

	// deselect row
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end

// vim:ft=objc

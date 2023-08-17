/**
 * File              : VKFeedViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 16.08.2023
 * Last Modified Date: 17.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "VKFeedViewController.h"
#include <stdio.h>
#include "Foundation/Foundation.h"
#include "cJSON.h"
#include "cVK.h"
#include "UIKit/UIKit.h"

@interface VKFeed : NSObject
@property (strong) NSString *text;
@property (strong) NSURL *image;
@end

@implementation VKFeed
- (id)init
{
	if (self = [super init]) {
		self.text = nil;
		self.image = nil;
	}
	return self;
}

@end

@implementation VKFeedViewController

- (void)viewDidLoad {
	UIBarButtonItem *menu = 
			[[UIBarButtonItem alloc]
					initWithImage:[UIImage imageNamed:@"menu_icon"] style:UIBarButtonItemStylePlain
					target:self action:@selector(menuButtonPushed:)]; 
	[self.navigationItem setLeftBarButtonItem:menu];
	self.title = @"Новости";

	// search bar
	self.searchBar = 
		[[UISearchBar alloc] initWithFrame:CGRectMake(0,70,320,44)];
	self.tableView.tableHeaderView=self.searchBar;	
	self.searchBar.delegate = self;
	self.searchBar.placeholder = @"Поиск:";

	// editing style
	self.tableView.allowsMultipleSelectionDuringEditing = false;
	
	// refresh control
	self.refreshControl=
		[[UIRefreshControl alloc]init];
	[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@""]];
	[self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

	//spinner
	self.spinner = 
		[[UIActivityIndicatorView alloc] 
		initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[self.tableView addSubview:self.spinner];
	self.spinner.tag = 12;

	// allocate array
	self.loadedData = [NSMutableArray array];

	// load data
	[self reloadData];
}

-(void)filterData{
	//if (self.searchBar.text && self.searchBar.text.length > 0)
		//self.data = [self.loadedData filteredArrayUsingPredicate:
				//[NSPredicate predicateWithFormat:@"self.name contains[c] %@", self.searchBar.text]];
	//else
		self.data = self.loadedData;
	[self.tableView reloadData];
}

void callback(void *data, const char *response, const char *error){
	if (error){
		NSLog(@"%s", error);
		UIAlertView *alert = 
				[[UIAlertView alloc]initWithTitle:@"error" 
				message:[NSString stringWithUTF8String:error] 
			  delegate:nil 
				cancelButtonTitle:@"Закрыть" 
				otherButtonTitles:nil];
		[alert show];
	}
	if (response){
		VKFeedViewController *self = data;
		// free data
		[self.loadedData removeAllObjects];

		NSString *str = [NSString stringWithUTF8String:response];
		NSData  *data = [str dataUsingEncoding:NSUTF8StringEncoding];	
		NSError *error = nil;
		NSDictionary *dict = 
			[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
		if (error){
			NSLog(@"%@", error);
			UIAlertView *alert = 
				[[UIAlertView alloc]initWithTitle:@"error to read json" 
				message:error.description
				delegate:nil 
				cancelButtonTitle:@"Закрыть" 
				otherButtonTitles:nil];
				[alert show];
				return;
		}
		// add feed items
		NSArray *items = [dict valueForKey:@"items"];
		for (NSDictionary *item in items){
			VKFeed *feed = [[VKFeed alloc]init];
			NSString *text = [item valueForKey:@"text"];
			feed.text = text;
			NSArray *attachments = [item valueForKey:@"attachments"];
			for (NSDictionary *attachment in attachments){
				NSString *type = [attachment valueForKey:@"type"];
				if ([type isEqualToString:@"photo"]){
					NSDictionary *photo = [attachment valueForKey:@"photo"];
					if (photo){
						NSArray *sizes = [photo valueForKey:@"sizes"];
						if (sizes){
							NSString *url = [(NSDictionary *)[sizes objectAtIndex:0]valueForKey:@"url"];
							feed.image = [NSURL URLWithString:url];
						}
					}
				}
				else if ([type isEqualToString:@"video"]){
					NSDictionary *video = [attachment valueForKey:@"video"];
					if (video){
						NSArray *image = [video valueForKey:@"image"];
						if (image){
							NSString *url = [(NSDictionary *)[image objectAtIndex:0]valueForKey:@"url"];
							feed.image = [NSURL URLWithString:url];
						}
					}
				}
			}
			[self.loadedData addObject:feed];
		}
		[self filterData];
		//UIAlertView *alert = 
				//[[UIAlertView alloc]initWithTitle:@"response" 
				//message:[NSString stringWithUTF8String:response]
				//delegate:nil 
				//cancelButtonTitle:@"Закрыть" 
				//otherButtonTitles:nil];
		//[alert show];
	}
}

-(void)reloadData{
	NSString *token = 
		[[NSUserDefaults standardUserDefaults]valueForKey:@"access_token"];
	// animate spinner
	CGRect rect = self.view.bounds;
	self.spinner.center = CGPointMake(rect.size.width/2, rect.size.height/2);
	if (!self.refreshControl.refreshing)
		[self.spinner startAnimating];

	dispatch_async(dispatch_get_main_queue(), ^{
			c_vk_run_method(
					[token UTF8String], 
					NULL, self, callback, 
					"newsfeed.get", NULL);	
		
			[self.spinner stopAnimating];
			[self.refreshControl endRefreshing];
			[self filterData];
	});
}

-(void)refresh:(id)sender{
	[self reloadData];
}

-(void)menuButtonPushed:(id)sender{
	[self.navigationController popViewControllerAnimated:true];
}
#pragma mark - NSURLConnectionDelegate Meythods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
     self.mdata = [[NSMutableData alloc]init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
     [self.mdata appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
     NSString  *filePath = [NSString stringWithFormat:@"%u/%@", NSDocumentDirectory,@"image.jpg"];
     [self.mdata writeToFile:filePath atomically:YES];
}

#pragma mark - TableViewDelegate Meythods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	VKFeed *feed = [self.data objectAtIndex:indexPath.item];
	UITableViewCell *cell = nil;
	//if ([file.type isEqual:@"dir"]){
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
		if (cell == nil){
			cell = [[UITableViewCell alloc]
							initWithStyle: UITableViewCellStyleDefault 
							reuseIdentifier: @"cell"];
			//cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
			//cell.imageView.image = [UIImage imageNamed:@"Directory"];
		}
	//} else {
		//cell = [self.tableView dequeueReusableCellWithIdentifier:@"file"];
		//if (cell == nil){
			//cell = [[UITableViewCell alloc]
			//initWithStyle: UITableViewCellStyleSubtitle 
			//reuseIdentifier: @"file"];
		//}
		////cell.detailTextLabel.text = [NSString stringWithFormat:@"%d Mb", self.selected.size/1024];
	//}
	if (feed.text)
		[cell.textLabel setText:feed.text];
	if (feed.image){
		// download image
		NSURLRequest *request = [NSURLRequest requestWithURL:feed.image];
		NSURLConnection *conection = 
				[[NSURLConnection alloc]initWithRequest:request delegate:self startImmediately:true];
		UIImage *image = [UIImage imageWithData:self.mdata];
		if (image)
			[cell.imageView setImage:image];
	}
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 60;
}

//- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	//self.selected = [self.data objectAtIndex:indexPath.item];
	//// open menu
	//UIActionSheet *as = 
			//[[UIActionSheet alloc]
				//initWithTitle:self.selected.name 
				//delegate:self 
				//cancelButtonTitle:@"Отмена" 
				//destructiveButtonTitle:@"Удалить" 
				//otherButtonTitles:@"Загрузить ZIP", @"Поделиться", nil];
	//[as showInView:tableView];
//}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//self.selected = [self.data objectAtIndex:indexPath.item];
	//if ([self.selected.type isEqual:@"dir"]){
		//// open directory in new controller
		//RootViewController *vc = [[RootViewController alloc]initWithFile:self.selected];
		//[self.navigationController pushViewController:vc animated:true];
		//// unselect row
		//[tableView deselectRowAtIndexPath:indexPath animated:true];
		//return;
	//}
	//// open menu
	//UIActionSheet *as = 
			//[[UIActionSheet alloc]
				//initWithTitle:self.selected.name 
				//delegate:self 
				//cancelButtonTitle:@"Отмена" 
				//destructiveButtonTitle:@"Удалить" 
				//otherButtonTitles:@"Открыть/Загрузить", @"Поделиться", nil];
	//[as showInView:tableView];
	//// unselect row
	//[tableView deselectRowAtIndexPath:indexPath animated:true];
//}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// hide keyboard
	[self.searchBar resignFirstResponder];
}

//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	//YDFile *file = [self.data objectAtIndex:indexPath.item];
	//return true;
//}

//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	//self.selected = nil;
	//if (editingStyle == UITableViewCellEditingStyleDelete){
		//self.selected = [self.data objectAtIndex:indexPath.item];
			//UIAlertView *alert = 
				//[[UIAlertView alloc]initWithTitle:@"Удалить файл?" 
				//message:self.selected.name 
				//delegate:self 
				//cancelButtonTitle:@"Отмена" 
				//otherButtonTitles:@"Удалить", nil];
			//[alert show];
	//}
//}

#pragma mark <SEARCHBAR FUNCTIONS>

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	[self filterData];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
}
@end

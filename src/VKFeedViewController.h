/**
 * File              : VKFeedViewController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 16.08.2023
 * Last Modified Date: 17.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
@interface VKFeedViewController : UITableViewController
<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, NSURLConnectionDelegate>
@property (strong) NSArray *data;
@property (strong) NSMutableArray *loadedData;
@property (strong) UISearchBar *searchBar;
@property (strong) UIActivityIndicatorView *spinner;
@property (strong) NSMutableData *mdata;

@end


// vim:ft=objc

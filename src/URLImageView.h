/**
 * File              : URLImageView.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 17.08.2023
 * Last Modified Date: 18.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>

@protocol URLImageViewDelegate <NSObject>
@optional
- (void)imageDidFinishLoading:(id)imageView;
@end

@interface  URLImageView : UIView 
<NSURLConnectionDelegate>
@property (strong) id<URLImageViewDelegate> delegate;
@property (strong) UIImageView *imageView;
@property (strong) NSMutableData *mutableData;
@property (strong) UIActivityIndicatorView *spinner;
- (id)initWithFrame:(CGRect)frame url:(NSURL *)url;

@end

// vim:ft=objc

/**
 * File              : URLImageView.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 17.08.2023
 * Last Modified Date: 18.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "URLImageView.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"

@implementation URLImageView

- (id)initWithFrame:(CGRect)frame url:(NSURL *)url {
	if (self = [super initWithFrame:frame]) {
		// imageview
		self.imageView = [[UIImageView alloc]initWithFrame:self.bounds];
		
		//spinner
		self.spinner = 
				[[UIActivityIndicatorView alloc] 
				initWithActivityIndicatorStyle:
				UIActivityIndicatorViewStyleGray];
		[self addSubview:self.spinner];
		self.spinner.tag = 12;
		self.spinner.center = CGPointMake(
				self.bounds.size.width/2, self.bounds.size.height/2);
		[self.spinner startAnimating];
		
		// download url 
		NSURLRequest *request = 
			[NSURLRequest requestWithURL:url];
		NSURLConnection *conection = 
				[[NSURLConnection alloc]initWithRequest:request
				 delegate:self startImmediately:true];
	}
	return self;
}

#pragma mark - NSURLConnectionDelegate Meythods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
     self.mutableData = [[NSMutableData alloc]init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
     [self.mutableData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
		[self.spinner stopAnimating];
		[self.spinner removeFromSuperview];
		[self.imageView setImage:[UIImage imageWithData:self.mutableData]];
		[self addSubview:self.imageView];
		if (self.delegate)
			[self.delegate imageDidFinishLoading:self];
}

@end


// vim:ft=objc

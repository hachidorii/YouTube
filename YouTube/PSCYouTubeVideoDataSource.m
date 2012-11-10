//
//  PSCYouTubeVideoDataSource.m
//  YouTube
//
//  Created by Chloe Stars on 11/5/12.
//  Copyright (c) 2012 Phantom Sun Creative. All rights reserved.
//

#import "PSCYouTubeVideoDataSource.h"
#import "PSCYouTubeVideoCellView.h"
#import "PSCYouTubeVideo.h"

@implementation PSCYouTubeVideoDataSource

- (id)init
{
	session = [PSCYouTubeSession new];
	[session setDeveloperKey:@"AI39si5u0pQxyJgbcC10IQgk76osOWlrpQeSGyvSF3UXwUq1wqYOyYEiOm7tEecGjPqMOS6kcuR-yB75h8aDbM1N2FiOeYjBBQ"];
	
	return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [videos count];
}

- (id)tableView:(NSTableView *)_tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	PSCYouTubeVideoCellView *result = [_tableView makeViewWithIdentifier:[tableColumn identifier] owner:nil];
	PSCYouTubeVideo *video = [videos objectAtIndex:row];
	[[result titleField] setStringValue:[video title]];
	NSURL *thumbnailURL = [video thumbnailURL];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^{
		[[result thumbnailView] setImage:nil];
		[[result thumbnailView] setImage:[[NSImage alloc] initWithContentsOfURL:thumbnailURL]];
	});
	[[result descriptionField] setStringValue:[video description]];
	
	// format listener and play count with commas/separators
	NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
	[numberFormatter setGroupingSize:3];
	[numberFormatter setUsesGroupingSeparator:YES];
	NSString *formattedViewCount = [numberFormatter stringFromNumber:[video viewCount]];
	
	NSString *viewsString = [[NSString alloc] initWithFormat:@"%@ views", formattedViewCount];
	
	[[result viewCountField] setStringValue:viewsString];
	//[[[result videoView] mainFrame] loadRequest:[NSURLRequest requestWithURL:[video videoURL]]];
	
	return result;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	// add autoplay to the end of the URL
	NSString *videoURLString = [[NSString alloc] initWithFormat:@"%@&autoplay=1&theme=light&modestbranding=1", [(PSCYouTubeVideo*)[videos objectAtIndex:rowIndex] videoURL]];
	[[videoView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:videoURLString]]];
	[windowController uncollpaseRightView];
	return YES;
}

- (void)refreshWithChannel:(PSCYouTubeChannel*)channel
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[session subscriptionWithChannel:channel completion:^(NSArray *_videos, NSError *error) {
			videos = _videos;
			// don't do anything
			/*for (PSCYouTubeVideo *video in videos) {
			 NSLog(@"title:%@", [video title]);
			 NSLog(@"thumbnailURL:%@", [video thumbnailURL]);
			 NSLog(@"description:%@", [video description]);
			 NSLog(@"viewCount:%@", [video viewCount]);
			 NSLog(@"videoURL:%@", [video videoURL]);
			 }*/
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				[tableView reloadData];
				[[scrollView contentView] scrollToPoint: NSMakePoint(0, 0)];
				[scrollView reflectScrolledClipView: [scrollView contentView]];
			});
		}];
	});
}

- (void)refreshWithWatchLater
{
	[session watchLaterWithCompletion:^(NSArray *_videos, NSError *error) {
		videos = _videos;
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[tableView reloadData];
			[[scrollView contentView] scrollToPoint: NSMakePoint(0, 0)];
			[scrollView reflectScrolledClipView: [scrollView contentView]];
		});
	}];
}

- (void)refreshWithSearch
{
	// this shouldn't load any videos into the table (in fact it should clear them), it should bring up the search box as part of the table view
	[session searchWithQuery:[searchField stringValue] completion:^(NSArray *_videos, NSError *error) {
		videos = _videos;
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[tableView reloadData];
			[[scrollView contentView] scrollToPoint: NSMakePoint(0, 0)];
			[scrollView reflectScrolledClipView: [scrollView contentView]];
		});
	}];
}

- (void)refreshWithMostPopular
{
	[session mostPopularWithCompletion:^(NSArray *_videos, NSError *error) {
		videos = _videos;
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[tableView reloadData];
			[[scrollView contentView] scrollToPoint: NSMakePoint(0, 0)];
			[scrollView reflectScrolledClipView: [scrollView contentView]];
		});
	}];
}
- (IBAction)share:(id)sender
{
	NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:@[[[videos objectAtIndex:[tableView selectedRow]] videoURL]]];
	sharingServicePicker.delegate = self;
	[sharingServicePicker showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}

- (NSArray *)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker sharingServicesForItems:(NSArray *)items proposedSharingServices:(NSArray *)proposedServices
{
	NSMutableArray *modifiedProposals = [NSMutableArray new];
	for (NSSharingService *proposedService in proposedServices) {
		if (![[proposedService title] isEqualToString:@"Add to Reading List"]) {
			[modifiedProposals addObject:proposedService];
		}
		//NSLog (@"title:%@", [proposedService title]);
	}

	return modifiedProposals;
}

@end

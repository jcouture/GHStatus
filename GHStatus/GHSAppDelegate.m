// GHSAppDelegate.m
//
// Copyright (c) 2012 Jean-Philippe Couture
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "GHSAppDelegate.h"
#import "GHSAPIClient.h"

static dispatch_source_t CreateDispatchTimer(uint64_t interval, uint64_t leeway, dispatch_queue_t queue, dispatch_block_t block) {
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

@interface GHSAppDelegate ()
@property (weak) IBOutlet NSMenu *menu;
@property (nonatomic, strong) NSStatusItem *statusItem;
- (void)updateStatusItem;
@end

@implementation GHSAppDelegate {
@private
    dispatch_source_t _timer;
}

- (void)awakeFromNib {
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [_statusItem setMenu:_menu];
    [self.statusItem setHighlightMode:YES];
    NSImage *image = [NSImage imageNamed:@"status-icon-black"];
    [self.statusItem setImage:image];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    __weak GHSAppDelegate *weakSelf = self;
    _timer = CreateDispatchTimer((300) * NSEC_PER_SEC, NSEC_PER_SEC, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [weakSelf updateStatusItem];
    });
}


#pragma mark - Private Implementation

- (void)updateStatusItem {
    __weak GHSAppDelegate *weakSelf = self;
    [[GHSAPIClient sharedClient] lastMessage:^(NSDictionary *lastMessage) {
        NSString *status = lastMessage[@"status"];
        NSString *message = lastMessage[@"body"];
        
        NSString *imageName = @"status-icon-black";
        NSString *alternateImageName = @"status-icon-black-inverted";
        
        if ([status isEqualToString:@"good"]) {
            imageName = @"status-icon-green";
            alternateImageName = @"status-icon-green-inverted";
        } else if ([status isEqualToString:@"minor"]) {
            imageName = @"status-icon-orange";
            alternateImageName = @"status-icon-orange-inverted";
        } else if ([status isEqualToString:@"major"]) {
            imageName = @"status-icon-red";
            alternateImageName = @"status-icon-red-inverted";
        }
        NSImage *image = [NSImage imageNamed:imageName];
        NSImage *alternateImage = [NSImage imageNamed:alternateImageName];
        
        [weakSelf.statusItem setImage:image];
        [weakSelf.statusItem setAlternateImage:alternateImage];
        [weakSelf.statusItem setToolTip:message];
    } failure:^(NSError *error) {
        NSImage *image = [NSImage imageNamed:@"status-icon-black"];
        [weakSelf.statusItem setImage:image];
        [weakSelf.statusItem setToolTip:nil];
    }];
}

@end
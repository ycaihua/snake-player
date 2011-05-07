//
//  snake_playerAppDelegate.h
//  snake-player
//
//  Created by John Altenmueller on 12/27/10.
//

#import <Cocoa/Cocoa.h>

@interface snake_playerAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end

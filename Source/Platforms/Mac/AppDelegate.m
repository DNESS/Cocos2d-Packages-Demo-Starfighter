#import "AppDelegate.h"
#import "GameMenuScene.h"
#import "CCFileUtils.h"
#import "Helper.h"
#import "SFKeyEventHandlingDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet CCGLView *glView;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    CCDirectorMac *director = (CCDirectorMac*) [CCDirector sharedDirector];

    // enable FPS and SPF
    // [director setDisplayStats:YES];

    // connect the OpenGL view with the director
    [director setView:self.glView];

    // 'Effects' don't work correctly when autoscale is turned on.
    // Use kCCDirectorResize_NoScale if you don't want auto-scaling.
    //[director setResizeMode:kCCDirectorResize_NoScale];

    // Enable "moving" mouse event. Default no.
    [self.window setAcceptsMouseMovedEvents:NO];

    // Center main window
    [self.window center];

    // Configure CCFileUtils to work with SpriteBuilder
    [CCBReader configureCCFileUtils];

    [CCFileUtils sharedFileUtils].directoriesDict =
        [@{ CCFileUtilsSuffixMac : @"resources-tablet",
            CCFileUtilsSuffixMacHD : @"resources-tablethd",
            CCFileUtilsSuffixDefault : @""} mutableCopy];

    [[CCFileUtils sharedFileUtils] setMacContentScaleFactor:2.0];

    GameMenuScene *gameMenuScene = [[GameMenuScene alloc] init];

    [director runWithScene:gameMenuScene];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{

}


@end

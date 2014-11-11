#import "SFDLCScene.h"
#import "SFBackgroundLayer.h"
#import "SFUIHelper.h"
#import "SFGameMenuScene.h"
#import "CCPackageManager.h"
#import "CCPackage.h"
#import "SFUIPackageControls.h"
#import "SFEntityFactory.h"
#import "CCPackageHelper.h"


static NSString *PACKAGE_NAME_PATCH_1_1 = @"patch_1_1";
static NSString *PACKAGE_NAME_LEVELS = @"levels";

@interface SFDLCScene()

@property (nonatomic, strong) NSMutableArray *packageControls;

@end


@implementation SFDLCScene

- (id)init
{
    self = [super init];

    if (self)
    {
        [CCPackageManager sharedManager].delegate = self;
        [CCPackageManager sharedManager].baseURL = [NSURL URLWithString:@"http://siner.de"];

        [self setupBackground];

        [self setupPackageControls];

        NSDictionary *buttonBack = [SFUIHelper createMenuButtonWithTitle:@"back" target:self selector:@selector(back) atRelPosition:ccp(0.5, 0.1)];
        [self addChild:buttonBack[@"effectNode"]];

        NSDictionary *buttonDeleteAll = [SFUIHelper createMenuButtonWithTitle:@"Delete All" target:self selector:@selector(deleteAll) atRelPosition:ccp(0.5, 0.2)];
        [self addChild:buttonDeleteAll[@"effectNode"]];
        CCButton *deleteButton = buttonDeleteAll[@"button"];
        [deleteButton setLabelColor:[CCColor redColor] forState:CCControlStateNormal];

        CCLabelTTF *title = [SFUIHelper gameLabelWithSize:36.0];
        title.string = @"Downloads";
        title.positionType = CCPositionTypeNormalized;
        title.position = ccp(0.5, 0.9);
        [self addChild:title];
    }

    return self;
}

- (void)deleteAll
{
    NSArray *packages = [[CCPackageManager sharedManager] allPackages];

    for (CCPackage *package in [packages copy])
    {
        NSError *error;
        if (![[CCPackageManager sharedManager] deletePackage:package error:&error])
        {
            NSLog(@"Error deleting package %@ with error %@", package, error);
        }
    }

    for (SFUIPackageControls *controls in _packageControls)
    {
        controls.package = nil;
    }

    [[SFEntityFactory sharedFactory] invalidateCache];
}

- (void)setupPackageControls
{
    self.packageControls = [NSMutableArray array];

    NSString *resolution = [CCPackageHelper defaultResolution];

    NSURL *patchPackageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/NickyWeber/Cocos2d-Packages-Demo-Starfighter/blob/master/Published-Packages/patch_1_1-iOS-%@.zip?raw=true", resolution]];
    SFUIPackageControls *control1 = [[SFUIPackageControls alloc] initWithPackageURL:patchPackageURL title:@"Patch 1.1" name:PACKAGE_NAME_PATCH_1_1 resolution:resolution];
    control1.positionType = CCPositionTypeNormalized;
    control1.position = ccp(0.5, 0.70);
    [self addChild:control1];
    [_packageControls addObject:control1];

    NSURL *levelsPackageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/NickyWeber/Cocos2d-Packages-Demo-Starfighter/blob/master/Published-Packages/levels-iOS-%@.zip?raw=true", resolution]];
    SFUIPackageControls *control2 = [[SFUIPackageControls alloc] initWithPackageURL:levelsPackageURL title:@"More Levels" name:PACKAGE_NAME_LEVELS resolution:resolution];
    [_packageControls addObject:control2];
    [self addChild:control2];
    control2.positionType = CCPositionTypeNormalized;
    control2.position = ccp(0.5, 0.475);
}

- (void)setupBackground
{
    SFBackgroundLayer *backgroundLayer = [SFBackgroundLayer node];
    [self addChild:backgroundLayer z:-1];
    backgroundLayer.newDebrisMinTime = 0.1;
    backgroundLayer.newDebrisVariance = 0.15;
    backgroundLayer.debrisBaseSpeed = 500.0;
    backgroundLayer.debrisSpeedVariance = 500.0;
}

- (void)back
{
    [[CCDirector sharedDirector] replaceScene:[[SFGameMenuScene alloc] init]
                               withTransition:[CCTransition transitionRevealWithDirection:CCTransitionDirectionDown duration:0.3]];
}

- (SFUIPackageControls *)controlsForPackage:(CCPackage *)package
{
    for (SFUIPackageControls *controls in _packageControls)
    {
        if (controls.package == package)
        {
            return controls;
        }
    }

    return nil;
}


#pragma mark - CCPackageManagerDelegate

- (void)packageInstallationFinished:(CCPackage *)package
{
    // Nothing to here
}

- (void)packageInstallationFailed:(CCPackage *)package error:(NSError *)error
{
    SFUIPackageControls *controls = [self controlsForPackage:package];
    [controls packageInstallationFailedWithError:error];
}

- (void)packageDownloadFinished:(CCPackage *)package
{
    // Nothing to here
}

- (void)packageDownloadFailed:(CCPackage *)package error:(NSError *)error
{
    SFUIPackageControls *controls = [self controlsForPackage:package];
    [controls packageDownloadFailedWithError:error];
}

- (void)packageUnzippingFinished:(CCPackage *)package
{
    // Nothing to here
}

- (void)packageUnzippingFailed:(CCPackage *)package error:(NSError *)error
{
    SFUIPackageControls *controls = [self controlsForPackage:package];
    [controls packageUnzippingFailedWithError:error];
}

- (void)packageDownloadProgress:(CCPackage *)package downloadedBytes:(NSUInteger)downloadedBytes totalBytes:(NSUInteger)totalBytes
{
    SFUIPackageControls *controls = [self controlsForPackage:package];
    [controls packageDownloadProgressDownloadedBytes:downloadedBytes totalBytes:totalBytes];
}

- (void)packageUnzippingProgress:(CCPackage *)package unzippedBytes:(NSUInteger)unzippedBytes totalBytes:(NSUInteger)totalBytes
{
    SFUIPackageControls *controls = [self controlsForPackage:package];
    [controls packageUnzippingProgressUnzippedBytes:unzippedBytes totalBytes:totalBytes];
}

@end

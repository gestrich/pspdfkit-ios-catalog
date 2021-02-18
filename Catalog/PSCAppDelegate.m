//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCAppDelegate.h"

#import "PSCAssetLoader.h"
#import "PSCCatalogViewController.h"
#import "PSCExample.h"
#import "PSCExampleManager.h"
#import "PSCFileHelper.h"
#import "Catalog-Swift.h"
#import "UIColor+PSCAdditions.h"

static NSString *const PSCCatalogSpotlightIndexName = @"PSCCatalogIndex";

@interface PSCAppDelegate ()
@property (nonatomic) PSCWindowCoordinator *windowCoordinator;
@end

@implementation PSCAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions {
    // Set your license key here. PSPDFKit is commercial software.
    // Each PSPDFKit license is bound to a specific app bundle id.
    // Visit https://customers.pspdfkit.com to get your demo or commercial license key.
    [PSPDFKitGlobal setLicenseKey:@"YOUR_LICENSE_KEY_GOES_HERE"];

    // Example how to customize appearance of navigation bars and toolbars.
    //[self customizeAppearanceOfNavigationBar];
    //[self customizeAppearanceOfToolbar];

    // Example how to easily change certain images in PSPDFKit.
    //[self customizeImages];

    // Example how to localize strings in PSPDFKit.
    //[self customizeLocalization];

    if (@available(iOS 13, *)) {
        // Handled by the SceneDelegate on >= iOS 13.
    } else {
        // Only create the window coordinator on < iOS 13.
        self.windowCoordinator = [PSCWindowCoordinator new];
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    // Configure callback for Open In Chrome feature. Optional.
    PSPDFKitGlobal.sharedInstance[PSPDFSettingKeyXCallbackURLString] = @"pspdfcatalog://";

    if (@available(iOS 13.0, *)) {
        // Handled by the SceneDelegate on >= iOS 13.
    } else {
        UIWindow *window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        [self.windowCoordinator installCatalogStackInWindow:window];

        // Opened with the Open In... feature?
        [self.windowCoordinator handleOpenURL:launchOptions[UIApplicationLaunchOptionsURLKey] options:launchOptions];
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)URL options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    NSLog(@"Open %@ from %@ (annotation: %@)", URL, options[UIApplicationLaunchOptionsSourceApplicationKey], options[UIApplicationLaunchOptionsAnnotationKey]);
    return [self.windowCoordinator handleOpenURL:URL options:options];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler {
    BOOL success = [self.windowCoordinator openShortcutItem:shortcutItem];
    completionHandler(success);
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options API_AVAILABLE(ios(13.0)) {
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc] initWithName:nil sessionRole:connectingSceneSession.role];
    configuration.sceneClass = UIWindowScene.class;
    configuration.delegateClass = SceneDelegate.class;
    return configuration;
}

#pragma mark - Customization

- (void)customizeImages {
    PSPDFKitGlobal.sharedInstance.imageLoadingHandler = ^UIImage *(NSString *imageName) {
        if ([imageName isEqualToString:@"knob"]) {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(20.0, 20.0), NO, 0.0);
            UIBezierPath *round = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 20.0, 20.0)];
            [round fill];
            UIImage *newKnob = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return newKnob;
        }
        return nil;
    };
}

- (void)customizeLocalization {
    // Either use the block-based system.
    PSPDFSetLocalizationBlock(^NSString *(NSString *stringToLocalize) {
        // This will look up strings in language/PSPDFKit.strings inside resources.
        // (In Catalog, there are no such files, this is just to demonstrate best practice)
        return NSLocalizedStringFromTable(stringToLocalize, @"PSPDFKit", nil);
        // return [NSString stringWithFormat:@"_____%@_____", stringToLocalize];
    });

    // Or override via dictionary.
    // See PSPDFKit.bundle/en.lproj/PSPDFKit.strings for all available strings.
    PSPDFSetLocalizationDictionary(@{ @"en": @{@"%d of %d": @"Page %d of %d", @"%d-%d of %d": @"Pages %d-%d of %d"} });
}

- (void)customizeAppearanceOfNavigationBar {
    // Use dynamic colors for light mode and dark mode in iOS 13. Default to light mode on iOS 12 and lower.
    UIColor *backgroundColor = [UIColor psc_colorForLightMode:[UIColor colorWithRed:1.00 green:0.72 blue:0.30 alpha:1.0] darkMode:[UIColor colorWithWhite:0.2 alpha:1]];
    UIColor *foregroundColor = [UIColor psc_colorForLightMode:[UIColor colorWithWhite:0.0 alpha:1] darkMode:[UIColor colorWithRed:1.00 green:0.80 blue:0.50 alpha:1.0]];

    // Always use the new appearance customization API on iOS 13 or higher.
    // More info: https://developer.apple.com/documentation/uikit/uinavigationbar#1654334
    if (@available(iOS 13, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        appearance.titleTextAttributes = @{ NSForegroundColorAttributeName: foregroundColor };
        appearance.largeTitleTextAttributes = @{ NSForegroundColorAttributeName: foregroundColor };
        appearance.backgroundColor = backgroundColor;

        UINavigationBar *appearanceProxy = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[PSPDFNavigationController.class]];
        appearanceProxy.standardAppearance = appearance;
        appearanceProxy.compactAppearance = appearance;
        appearanceProxy.scrollEdgeAppearance = appearance;
        appearanceProxy.tintColor = foregroundColor;
    } else {
        UINavigationBar *appearanceProxy = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[PSPDFNavigationController.class]];
        appearanceProxy.titleTextAttributes = @{ NSForegroundColorAttributeName: foregroundColor };
        appearanceProxy.largeTitleTextAttributes = @{ NSForegroundColorAttributeName: foregroundColor };
        appearanceProxy.barTintColor = backgroundColor;
        appearanceProxy.tintColor = foregroundColor;
    }

    // Repeat the same customization steps for
    // [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[PSPDFNavigationController.class, UIPopoverPresentationController.class]];
    // if you want to customize the look of navigation bars in popovers on iPad as well.
}

- (void)customizeAppearanceOfToolbar {
    // Use dynamic colors for light mode and dark mode in iOS 13. Default to light mode on iOS 12 and lower.
    UIColor *backgroundColor = [UIColor psc_colorForLightMode:[UIColor colorWithRed:0.77 green:0.88 blue:0.65 alpha:1.0] darkMode:[UIColor colorWithWhite:0.2 alpha:1]];
    UIColor *foregroundColor = [UIColor psc_colorForLightMode:[UIColor colorWithWhite:0.0 alpha:1] darkMode:[UIColor colorWithRed:0.86 green:0.93 blue:0.78 alpha:1.0]];

    // Always use the new appearance customization API on iOS 13 or higher.
    // More info: https://developer.apple.com/documentation/uikit/uitoolbar#1652878
    if (@available(iOS 13, *)) {
        UIToolbarAppearance *appearance = [[UIToolbarAppearance alloc] init];
        appearance.backgroundColor = backgroundColor;

        PSPDFFlexibleToolbar *appearanceProxy = [PSPDFFlexibleToolbar appearance];
        appearanceProxy.standardAppearance = appearance;
        appearanceProxy.compactAppearance = appearance;
        appearanceProxy.tintColor = foregroundColor;
    } else {
        PSPDFFlexibleToolbar *appearanceProxy = [PSPDFFlexibleToolbar appearance];
        appearanceProxy.barTintColor = backgroundColor;
        appearanceProxy.tintColor = foregroundColor;
    }
}

@end

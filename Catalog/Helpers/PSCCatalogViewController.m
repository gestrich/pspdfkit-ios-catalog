//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCCatalogViewController.h"

#import "PSCContent.h"
#import "PSCExample.h"
#import "PSCExampleManager.h"
#import "PSCMacros.h"
#import "PSCSectionDescriptor.h"
#import "UIColor+PSCDefaults.h"
#import <objc/runtime.h>
#import <QuickLook/QuickLook.h>

#if BUILDING_FOR_VIEWER
#import <CatalogForViewer/CatalogForViewer-Swift.h>
#elif BUILDING_FOR_CATALOG
#import "Catalog-Swift.h"
#endif

@interface PSCCatalogViewController () <PSPDFDocumentDelegate, UISearchResultsUpdating, PSCExampleRunnerDelegate, UIAdaptivePresentationControllerDelegate> {
    BOOL _shouldRestoreState;
    BOOL _shouldHideSearchBar;
    BOOL _clearCacheNeeded;
}
@property (nonatomic, copy) NSArray<PSCSectionDescriptor *> *content;
@property (nonatomic, copy) NSArray<PSCContent *> *searchContent;
@property (nonatomic) UISearchController *searchController;
@property (nonatomic) PSCExampleLanguage preferredExampleLanguage;
@end

static NSString *const PSCLastIndexPath = @"PSCLastIndexPath";
static NSString *const PSCCatalogExamplePreferenceLanguageKey = @"PSCCatalogExamplePreferenceLanguage";

@implementation PSCCatalogViewController

@synthesize preferredExampleLanguage = _preferredExampleLanguage;

#pragma mark - Lifecycle

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if ((self = [super initWithStyle:style])) {
        self.title = @"PSPDFKit Catalog";
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Catalog" style:UIBarButtonItemStylePlain target:nil action:nil];

        self.languageSelectionEnabled = YES;

        [self restorePreferredExampleLanguage];

        // iOS 13 changed the API, however we support iOS 12+.
        PSC_CATALYST_DEPRECATED_NOWARN([self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"f" modifierFlags:UIKeyModifierCommand action:@selector(beginSearch:) discoverabilityTitle:@"Search"]];)
    }
    return self;
}

- (void)restoreUserActivityState:(NSUserActivity *)activity {
    if (activity.psc_isOpenExampleActivity) {
        self.preferredExampleLanguage = activity.psc_preferredExampleLanguage;
        NSIndexPath *indexPath = activity.psc_indexPath;

        if (indexPath.section > 1) {
            NSIndexPath *sectionHeaderIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
            [self.tableView selectRowAtIndexPath:sectionHeaderIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            [self tableView:self.tableView didSelectRowAtIndexPath:sectionHeaderIndexPath];
        }

        // Restore session but fail gracefully
        @try {
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        } @catch(...) {}
    }
}

#pragma mark - Content Creation

- (void)createTableContent {
    NSMutableOrderedSet<PSCSectionDescriptor *> *sections = [NSMutableOrderedSet orderedSet];
    NSArray<PSCExample *> *examples = [PSCExampleManager.defaultManager examplesForPreferredLanguage:self.preferredExampleLanguage];

    // Add examples and map categories to sections.
    PSCExampleCategory currentCategory = -1;
    PSCSectionDescriptor *currentSection;
    for (PSCExample *example in examples) {
        if (currentCategory != example.category) {
            if (currentSection && currentSection.contentDescriptors.count > 1) {
                [sections addObject:currentSection];
            }

            currentCategory = example.category;
            currentSection = [PSCSectionDescriptor sectionWithTitle:PSCHeaderFromExampleCategory(currentCategory) footer:PSCFooterFromExampleCategory(currentCategory)];

            if (currentCategory == PSCExampleCategoryIndustryExamples) {
                currentSection.headerView = self.topHeaderView;
                currentSection.isCollapsed = NO;
            } else {
                if (currentCategory == PSCExampleCategoryTop) {
                    currentSection.isCollapsed = NO;
                }
                [currentSection addContent:[PSCContent sectionHeaderContentWithTitle:PSCHeaderFromExampleCategory(currentCategory) description:PSCFooterFromExampleCategory(currentCategory)]];
            }
        }

        PSCContent *exampleContent = [PSCContent contentWithTitle:example.title image:example.image description:example.contentDescription];
        exampleContent.example = example;
        [currentSection addContent:exampleContent];
    }

    if (currentSection && currentSection.contentDescriptors.count > 0) {
        [sections addObject:currentSection];
    }

    if (self.shouldCombineSections) {
        PSCSectionDescriptor *combinedSection = sections.firstObject;
        NSMutableArray<PSCContent *> *allContent = [NSMutableArray new];
        for (PSCSectionDescriptor *section in sections) {
            for (PSCContent *content in section.contentDescriptors) {
                if (!content.isSectionHeader) {
                    [allContent addObject:content];
                }
            }
        }
        combinedSection.contentDescriptors = [allContent copy];
        self.content = @[combinedSection];
    } else {
        self.content = sections.array;
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    #if BUILDING_FOR_CATALOG
    [self addDebugButton];
    #endif

    [self createTableContent];
    if ([NSProcessInfo.processInfo.arguments containsObject:@"--clear-all-caches"]) {
        _clearCacheNeeded = YES;
    }

    __auto_type configureTableViewForSearch = ^(UITableView *tableView) {
        BOOL isRootTableView = tableView == self.tableView;
        tableView.delegate = self;
        tableView.dataSource = self;
        // We're not using headers for the search table view
        tableView.estimatedSectionHeaderHeight = isRootTableView ? 30 : 0;

        tableView.cellLayoutMarginsFollowReadableWidth = YES;
    };

    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

    UITableView *tableView = self.tableView;
    configureTableViewForSearch(tableView);
    // Make sure that we can preserve the selection in state restoration
    tableView.restorationIdentifier = @"Samples Table";

    // Present the search display controller on this view controller
    self.definesPresentationContext = YES;

    UITableViewStyle style = UITableViewStyleGrouped;
    if (@available(iOS 13, *)) {
        style = UITableViewStyleInsetGrouped;
    }

    UITableViewController *resultsController = [[UITableViewController alloc] initWithStyle:style];
    configureTableViewForSearch(resultsController.tableView);

    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:resultsController];
    searchController.searchResultsUpdater = self;
    self.searchController = searchController;

    // Enables workarounds for rdar://352525 and rdar://32630657.
    [searchController pspdf_installWorkaroundsOn:self];
    self.navigationItem.searchController = searchController;

    if (@available(iOS 13, *)) {
        // Don't use custom state restoration on iOS 13,
        // since this messes with multiple windows.
        // We use the system user activity state restoration there.
        _shouldRestoreState = NO;
    } else {
        _shouldRestoreState = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UITableView *tableView = self.tableView;
    NSIndexPath *tableViewIndexPath = tableView.indexPathForSelectedRow;
    if (tableViewIndexPath != nil) {
        [tableView deselectRowAtIndexPath:tableViewIndexPath animated:YES];
    }

    [self.navigationController setToolbarHidden:YES animated:animated];

    // clear cache (for night mode)
    if (_clearCacheNeeded) {
        _clearCacheNeeded = NO;
        [PSPDFKitGlobal.sharedInstance.cache clearCache];
    }

    if (_shouldHideSearchBar) {
        tableView.contentOffset = CGPointMake(0, self.searchController.searchBar.frame.size.height - tableView.contentInset.top);
        _shouldHideSearchBar = NO;
    }
}

- (void)setWindow:(UIWindow *)window {
    _window = window;
    [self applyCatalogAppearance];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Restore last selected sample if appropriate with support for reset from settings:
    static NSString *const PSCResetKey = @"psc_reset";

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults boolForKey:PSCResetKey] || [self shouldResetForArguments:NSProcessInfo.processInfo.arguments]) { // the launch argument SHOULD override the user defaults, however it does not when launched through an XCUIApplication launch.
        [defaults removeObjectForKey:PSCResetKey];
        [defaults synchronize];
        _shouldRestoreState = NO;
    }
    if (!_shouldRestoreState) {
        [self saveAppStateIfPossible];
    } else {
        _shouldRestoreState = NO;
        NSData *pathData = [defaults objectForKey:PSCLastIndexPath];
        if (!pathData) return;
        NSIndexPath *path = [NSKeyedUnarchiver unarchivedObjectOfClass:NSIndexPath.class fromData:pathData error:NULL];
        UITableView *table = self.tableView;
        [table selectRowAtIndexPath:path animated:animated scrollPosition:UITableViewScrollPositionNone];

        @try {
            [self tableView:self.tableView didSelectRowAtIndexPath:path];
        } @catch (NSException *exception) {
            NSLog(@"Failed to restore last example: %@", exception);
        }
    }

    [self clearWindowScene];
}

- (BOOL)shouldResetForArguments:(NSArray<NSString *> *)processArguments {
    //NSLog(@"Launch arguments: %@", processArguments);
    NSUInteger resetParameter = [processArguments indexOfObjectPassingTest:^BOOL(NSString *argument, NSUInteger _, BOOL *__) {
        // look for both: -psc_reset and --psc_reset
        return [argument hasSuffix:@"psc_reset"];
    }];

    if (resetParameter == NSNotFound) {
        return NO;
    }

    // Assume we should reset if no argument is given to the parameter
    if (resetParameter == processArguments.count - 1) {
        return YES;
    }

    // Otherwise, use the bool value of the succeeding argument
    return processArguments[resetParameter + 1].boolValue;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Key Commands

- (IBAction)beginSearch:(id)sender {
    [self.searchController.searchBar becomeFirstResponder];
}

#pragma mark - Private

- (BOOL)isValidIndexPath:(NSIndexPath *)indexPath forContent:(NSArray<PSCSectionDescriptor *> *)content {
    BOOL isValid = NO;
    if (indexPath) {
        NSInteger numberOfSections = content.count;
        NSInteger numberOfRowsInSection = 0;
        if (indexPath.section < numberOfSections) {
            numberOfRowsInSection = content[indexPath.section].contentDescriptors.count;
            if (indexPath.row < numberOfRowsInSection) {
                isValid = YES;
            }
        }
    }
    return isValid;
}

- (nullable PSCContent *)contentDescriptorForIndexPath:(nonnull NSIndexPath *)indexPath tableView:(nullable UITableView *)tableView {
    // Get correct content descriptor
    PSCContent *contentDescriptor;
    if (!tableView || tableView == self.tableView) {
        NSAssert([self isValidIndexPath:indexPath forContent:self.content], @"Index path must be valid");
        contentDescriptor = (self.content[indexPath.section]).contentDescriptors[indexPath.row];
    } else {
        NSAssert(indexPath.row >= 0 && (NSUInteger)indexPath.row < self.searchContent.count, @"Index path must be valid");
        contentDescriptor = self.searchContent[indexPath.row];
    }
    return contentDescriptor;
}

- (nullable PSCExample *)exampleForIndexPath:(nonnull NSIndexPath *)indexPath tableView:(nullable UITableView *)tableView {
    PSCContent *contentDescriptor = [self contentDescriptorForIndexPath:indexPath tableView:tableView];
    return contentDescriptor.example;
}

- (void)setPreferredExampleLanguage:(PSCExampleLanguage)preferredExampleLanguage {
    _preferredExampleLanguage = preferredExampleLanguage;
    [NSUserDefaults.standardUserDefaults setInteger:preferredExampleLanguage forKey:PSCCatalogExamplePreferenceLanguageKey];
    if (self.isViewLoaded) {
        [self createTableContent];
        [self.tableView reloadData];
    }
}

- (PSCExampleLanguage)preferredExampleLanguage {
    return _preferredExampleLanguage;
}

- (void)restorePreferredExampleLanguage {
    self.preferredExampleLanguage = (PSCExampleLanguage)[NSUserDefaults.standardUserDefaults integerForKey:PSCCatalogExamplePreferenceLanguageKey];
}

- (void)clearWindowScene {
    if (@available(iOS 13.0, *)) {
        UIWindowScene *windowScene = self.window.windowScene;
        windowScene.userActivity = nil;
        windowScene.title = @"PSPDFKit Catalog";
        windowScene.session.stateRestorationActivity = nil;
    }
}

#pragma mark - Appearance

- (void)applyCatalogAppearance {
    UIColor *color = UIColor.psc_catalogTintColor;

    // Global (the window reference should be set by the application delegate early in the app lifecycle)
    self.window.tintColor = color;

    // The accessory view lives on the keyboard window, so it doesn't auto inherit the window tint color
    [PSPDFFreeTextAccessoryView appearance].tintColor = color;
}

#pragma mark - Views

- (UIView *)topHeaderView {
    UITableViewHeaderFooterView *headerView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:nil];
    UIView *contentView = headerView.contentView;
    const CGFloat topBottomMargin = 16;

    UIImage *image = [[UIImage psc_imageNamed:@"pspdfkit-logo"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *logo = [[UIImageView alloc] initWithImage:image];
    logo.tintColor = UIColor.psc_textColor;
    [contentView addSubview:logo];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [logo setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    NSLayoutConstraint *top = [logo.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:topBottomMargin];
    // Ensures the layout is not ambiguous while UITableView height calculation is still in flux.
    top.priority = UILayoutPriorityRequired - 1;
    top.active = YES;
    [logo.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-topBottomMargin-4].active = YES;
    [logo.leadingAnchor constraintEqualToAnchor:contentView.readableContentGuide.leadingAnchor].active = YES;

    UILabel *version = [[UILabel alloc] init];
    version.textColor = logo.tintColor;
    version.attributedText = self.versionString;
    version.numberOfLines = 2;
    [contentView addSubview:version];
    version.translatesAutoresizingMaskIntoConstraints = NO;
    [version.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:8].active = YES;
    [version.centerYAnchor constraintEqualToAnchor:logo.centerYAnchor].active = YES;

    if (self.languageSelectionEnabled) {
        NSArray<NSString *> *titles = @[@"Swift", @"ObjC"];
        UISegmentedControl *filter = [[UISegmentedControl alloc] initWithItems:titles];
        filter.selectedSegmentIndex = self.preferredExampleLanguage;
        [filter addTarget:self action:@selector(preferredExampleLanguageChanged:) forControlEvents:UIControlEventValueChanged];
        [contentView addSubview:filter];
        filter.translatesAutoresizingMaskIntoConstraints = NO;
        [filter setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [filter.centerYAnchor constraintEqualToAnchor:logo.centerYAnchor].active = YES;
        [filter.trailingAnchor constraintEqualToAnchor:contentView.readableContentGuide.trailingAnchor].active = YES;
        [version.trailingAnchor constraintLessThanOrEqualToAnchor:filter.leadingAnchor constant:-4].active = YES;
    }

    return headerView;
}

- (NSAttributedString *)versionString {
    NSString *version = PSPDFKitGlobal.versionString;
    NSMutableAttributedString *attibuted = [[NSMutableAttributedString alloc] initWithString:version attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}];
    NSRange kitRange = [version rangeOfString:@"PSPDFKit"];
    if (kitRange.location != NSNotFound) {
        [attibuted addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14] range:kitRange];
    }
    return attibuted;
}

#pragma mark - Actions

- (void)preferredExampleLanguageChanged:(UISegmentedControl *)sender {
    [self setPreferredExampleLanguage:sender.selectedSegmentIndex];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return tableView == self.tableView ? self.content.count : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return tableView == self.tableView ? (self.content[section]).isCollapsed ? 1 : (self.content[section]).contentDescriptors.count : self.searchContent.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return tableView == self.tableView ? (self.content[section]).headerView : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const PSCCellIdentifier = @"PSCatalogCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PSCCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:PSCCellIdentifier];
    }

    PSCContent *contentDescriptor = [self contentDescriptorForIndexPath:indexPath tableView:tableView];
    cell.textLabel.text = contentDescriptor.title;
    cell.textLabel.font = contentDescriptor.isSectionHeader ? [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline] : [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.text = contentDescriptor.contentDescription;
    cell.detailTextLabel.textColor = UIColor.psc_secondaryTextColor;
    cell.detailTextLabel.numberOfLines = 0;
    cell.imageView.image = contentDescriptor.image;
    cell.accessoryView = [self accessoryViewForTableView:tableView cellForRowAtIndexPath:indexPath];

    return cell;
}

- (UIView *)accessoryViewForTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIImageView *badgeView = [[UIImageView alloc] init];
    UIImage *arrowImage = [[PSPDFKitGlobal imageNamed:@"arrow-right-landscape"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *arrowView = [[UIImageView alloc] initWithImage:arrowImage];
    arrowView.contentMode = UIViewContentModeCenter;

    if (indexPath.section > 0 && indexPath.row == 0) {
        // Make arrow point down/up when the cell is the "header cell" of the section.
        if (self.content[indexPath.section].isCollapsed) {
            arrowView.transform = CGAffineTransformMakeRotation((CGFloat)M_PI_2);
        } else {
            arrowView.transform = CGAffineTransformMakeRotation((CGFloat)-M_PI_2);
        }
    } else {
        // Set the appropriate badge for example cells and add a standard disclosure.
        if (self.languageSelectionEnabled) {
            PSCContent *contentDescriptor = [self contentDescriptorForIndexPath:indexPath tableView:tableView];
            BOOL isSwift = contentDescriptor.example.isSwift;
            badgeView.image = [UIImage psc_imageNamed:isSwift ? @"swift-badge" : @"objc-badge"];
        }
        arrowView.image = arrowImage.imageFlippedForRightToLeftLayoutDirection;
    }

    UIStackView *accessoryView = [[UIStackView alloc] initWithArrangedSubviews:@[badgeView, arrowView]];
    accessoryView.tintColor = UIColor.psc_accessoryViewColor;
    accessoryView.spacing = 8;
    accessoryView.axis = UILayoutConstraintAxisHorizontal;
    CGSize size = [accessoryView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    accessoryView.bounds = (CGRect) {.size = size};
    return accessoryView;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PSCContent *contentDescriptor = [self contentDescriptorForIndexPath:indexPath tableView:tableView];

    __block NSIndexPath *unfilteredIndexPath;
    if (tableView == self.tableView) {
        // Expand/collapse section
        if (indexPath.section > 0 && indexPath.row == 0) {
            PSCSectionDescriptor *section = self.content[indexPath.section];
            section.isCollapsed = !section.isCollapsed;
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            return;
        }

        unfilteredIndexPath = indexPath;
    } else {
        // Find original index path so we can persist.
        [self.content enumerateObjectsUsingBlock:^(PSCSectionDescriptor *section, NSUInteger sectionIndex, BOOL *stop) {
            [section.contentDescriptors enumerateObjectsUsingBlock:^(PSCContent *content, NSUInteger contentIndex, BOOL *stop2) {
                if (content == contentDescriptor) {
                    unfilteredIndexPath = [NSIndexPath indexPathForRow:contentIndex inSection:sectionIndex];
                    *stop = YES;
                    *stop2 = YES;
                }
            }];
        }];
    }
    [self saveAppStateIfPossible];

    NSUserActivity *activity = [NSUserActivity psc_openExampleActivityWithPreferredExampleLanguage:self.preferredExampleLanguage indexPath:unfilteredIndexPath];

    PSCExample *example = contentDescriptor.example;

    if (@available(iOS 13.0, *)) {
        UIWindowScene *windowScene = self.window.windowScene;
        windowScene.userActivity = activity;
        windowScene.title = example.title;
        windowScene.session.stateRestorationActivity = activity;
    }

    [self openExample:example atIndexPath:indexPath inTableView:tableView];
}

- (void)openExample:(PSCExample *)example atIndexPath:(nullable NSIndexPath *)indexPath inTableView:(UITableView *)tableView {
    UIViewController *controller = [example invokeWithDelegate:self];
    if (!controller) {
        // No controller returned, maybe the example just presented an alert controller.
        if (indexPath) {
            [tableView deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:YES];
        }
        return;
    }
    if (example.wantsModalPresentation) {
        UINavigationController *navController;
        if ([controller isKindOfClass:UINavigationController.class]) {
            navController = (id)controller;
        } else {
            if (example.embedModalInNavigationController) {
                navController = [[PSPDFNavigationController alloc] initWithRootViewController:controller];
            }
            if (example.customizations) {
                example.customizations(navController);
            }

            navController.popoverPresentationController.sourceView = indexPath != nil ? ([tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath] ?: tableView) : tableView;
        }
        navController.presentationController.delegate = self;
        navController.navigationBar.prefersLargeTitles = example.prefersLargeTitles;
        UIViewController *controllerToPresent = navController ?: controller;
        [self presentViewController:controllerToPresent animated:YES completion:nil];
        if (indexPath) {
            [tableView deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:YES];
        }
    } else {
        if ([controller isKindOfClass:[UINavigationController class]]) {
            controller = ((UINavigationController *)controller).topViewController;
        }
        self.navigationController.presentationController.delegate = self;
        self.navigationController.navigationBar.prefersLargeTitles = example.prefersLargeTitles;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (BOOL)openExampleWithType:(NSString *)exampleType {
    NSArray<PSCExample *> *examples = PSCExampleManager.defaultManager.allExamples;
    PSCExample *filteredExample;
    for (PSCExample *example in examples) {
        if ([example.type isEqual:exampleType]) {
            filteredExample = example;
        }
    }
    if (filteredExample) {
        [self openExample:filteredExample atIndexPath:nil inTableView:self.tableView];
    }
    return NO;
}

#pragma mark - PSPDFDocumentDelegate

- (void)pdfDocumentDidSave:(PSPDFDocument *)document {
    PSCLog(@"\n\nSaving of %@ successful.", document);
}

- (void)pdfDocument:(PSPDFDocument *)document saveDidFailWithError:(NSError *)error {
    PSCLog(@"\n\n Warning: Saving of %@ failed: %@", document, error);
}

#pragma mark UISearchResultsUpdating and content filtering

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    UISearchBar *searchBar = searchController.searchBar;
    [self filterContentForSearchText:searchBar.text scope:searchBar.scopeButtonTitles[searchBar.selectedScopeButtonIndex]];
}

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope {
    NSMutableArray *filteredContent = [NSMutableArray array];

    if (searchText.length > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.title CONTAINS[cd] %@ AND self.isSectionHeader = NO", searchText];
        for (PSCSectionDescriptor *section in self.content) {
            [filteredContent addObjectsFromArray:[section.contentDescriptors filteredArrayUsingPredicate:predicate]];
        }
    }
    self.searchContent = filteredContent;

    [((UITableViewController *)self.searchController.searchResultsController).tableView reloadData];
}

#pragma mark - Debug Helper

#if BUILDING_FOR_CATALOG

- (void)addDebugButton {
    UIBarButtonItem *debugButton = [[UIBarButtonItem alloc] initWithTitle:@"Debug" style:UIBarButtonItemStylePlain target:self action:@selector(didTapDebugButtonItem:)];
    self.navigationItem.rightBarButtonItem = debugButton;
}

- (void)didTapDebugButtonItem:(UIBarButtonItem *)sender {
    UIAlertAction *memoryAction = [UIAlertAction actionWithTitle:@"Raise Memory Warning" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       [self debugCreateLowMemoryWarning];
    }];

    UIAlertAction *cacheAction = [UIAlertAction actionWithTitle:@"Clear Cache" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self debugClearCache];
    }];

    UIAlertController *debugSheet = [UIAlertController alertControllerWithTitle:@"Debug Menu" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [debugSheet addAction:memoryAction];
    [debugSheet addAction:cacheAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [debugSheet addAction:cancelAction];

    debugSheet.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:debugSheet animated:YES completion:nil];
}

// Only for debugging - this will get you rejected on the App Store!
- (void)debugCreateLowMemoryWarning {
    PSC_SILENCE_CALL_TO_UNKNOWN_SELECTOR([UIApplication.sharedApplication performSelector:NSSelectorFromString([NSString stringWithFormat:@"_%@Warning", @"performMemory"])];)
    // Clear any reference of items that would retain controllers/pages.
    [UIMenuController.sharedMenuController setMenuItems:nil];
}

- (void)debugClearCache {
    [PSPDFKitGlobal.sharedInstance.renderManager.renderQueue cancelAllTasks];
    [PSPDFKitGlobal.sharedInstance.cache clearCache];
}

#endif

#pragma mark - PSCExampleRunner

- (nullable UIViewController *)currentViewController {
    return self;
}

- (void)saveAppStateIfPossible {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSIndexPath *currentSamplePath = self.tableView.indexPathForSelectedRow;
    if (currentSamplePath) {
        NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:currentSamplePath requiringSecureCoding:YES error:NULL];
        [defaults setObject:archiveData forKey:PSCLastIndexPath];
        
    } else {
        [defaults removeObjectForKey:PSCLastIndexPath];
    }
    [defaults synchronize];
}

#pragma mark - UIAdaptivePresentationControllerDelegate

// This is called when dismissing non-fullscreen presentations.
// On iOS 13, presentations that don't cover the full screen, don't call the underlying controllers
// viewDidDisappear and viewDidAppear on dismissal.
- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    [self clearWindowScene];
}

@end

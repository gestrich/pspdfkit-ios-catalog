//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCExampleManager.h"

#import "PSCMacros.h"
#import "PSCExample.h"
#import <objc/runtime.h>

@interface PSCExampleManager ()
@property (nonatomic, copy) NSArray *allExamples;
@end

@implementation PSCExampleManager

#pragma mark - Static

+ (PSCExampleManager *)defaultManager {
    static PSCExampleManager *_manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [self.class new];
    });
    return _manager;
}

#pragma mark - Lifecycle

- (instancetype)init {
    if ((self = [super init])) {
        _allExamples = [self loadAllExamples];
    }
    return self;
}

- (NSArray *)loadAllExamples {
    // Get all subclasses and instantiate them.
    NSArray *exampleSubclasses = PSCGetAllExampleSubclasses();
    NSMutableArray *examples = [NSMutableArray array];
    PSCExampleTargetDeviceMask currentDevice = PSCIsIPad() ? PSCExampleTargetDeviceMaskPad : PSCExampleTargetDeviceMaskPhone;
    for (Class exampleObj in exampleSubclasses) {
        PSCExample *example = [exampleObj new];
        if ((example.targetDevice & currentDevice) > 0) {
            [examples addObject:example];
        }
    }

    // Sort all examples depending on category.
    [examples sortUsingComparator:^NSComparisonResult(PSCExample *example1, PSCExample *example2) {
        // sort via category
        if (example1.category < example2.category)
            return (NSComparisonResult)NSOrderedAscending;
        else if (example1.category > example2.category)
            return (NSComparisonResult)NSOrderedDescending;
        // then priority
        else if (example1.priority < example2.priority)
            return (NSComparisonResult)NSOrderedAscending;
        else if (example1.priority > example2.priority)
            return (NSComparisonResult)NSOrderedDescending;
        // then title
        else
            return [example1.title compare:example2.title];
    }];

    // Sets the `isAnotherLanguageCounterPartExampleAvailable` flag of an example
    for (PSCExample *example in examples) {
        if (example.isCounterpartExampleAvailable) {
            continue;
        }

        // We are using the title as a unique identifier for an example showing a particular thing.
        // That is we are assuming that an example written in both Objective-C and Swift has the same title.
        // We need to make sure that even the new examples created in both languages do the follow the rule of having the same titles.
        NSArray<PSCExample *> *counterpartExamples = [examples filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K LIKE %@", @"title", example.title]];

        if (counterpartExamples.count > 1) {
            example.isCounterpartExampleAvailable = YES;
            counterpartExamples.lastObject.isCounterpartExampleAvailable = YES;
        } else {
            example.isCounterpartExampleAvailable = NO;
        }
    }

    return examples;
}

- (NSArray<PSCExample *> *)examplesForPreferredLanguage:(PSCExampleLanguage)preferredLanguage {
    NSMutableArray<PSCExample *> *examples = [NSMutableArray array];

    for (PSCExample *example in self.allExamples) {
        PSCExampleLanguage exampleLanguage = example.isSwift ? PSCExampleLanguageSwift : PSCExampleLanguageObjectiveC;
        if (exampleLanguage == preferredLanguage || !example.isCounterpartExampleAvailable) {
            [examples addObject:example];
        }
    }
    return [NSArray arrayWithArray:examples];
}

#pragma mark - Annotation Type runtime builder

/// Returns a list of classes encountered when walking the class hierarchy from subclass to superclass.
/// Returns `nil`, if subclass is not a subclass of superclass.
NS_INLINE  NSArray<Class> * _Nullable PSCClassHierarchy(Class subclass, Class superclass) {
    // Do not use -[NSObject isSubclassOfClass:] in order to avoid calling +initialize on all classes.
    for (Class class = class_getSuperclass(subclass); class != Nil; class = class_getSuperclass(class)) {
        if (class == superclass) {
            // We walk the hierarchy again instead of temporarily storing all encountered classes
            // to avoid triggering +initialize and potentially hitting threading checks on system classes.
            NSMutableArray<Class> *encounteredClasses = [NSMutableArray<Class> new];
            for (Class c = class_getSuperclass(subclass); c != superclass; c = class_getSuperclass(c)) {
                [encounteredClasses addObject:c];
            }
            return [encounteredClasses copy];
        }
    }
    return nil;
}

static NSArray *PSCGetAllExampleSubclasses(void) {
    NSMutableArray<Class> *classes = [NSMutableArray<Class> new];
    NSMutableSet<Class> *intermediaryClasses = [NSMutableSet<Class> new];
    unsigned int count = 0;
    Class *classList = objc_copyClassList(&count);
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
    dispatch_apply(count, queue, ^(size_t idx) {
        __unsafe_unretained Class class = classList[idx];
        NSArray<Class> *encounteredClasses = PSCClassHierarchy(class, PSCExample.class);
        if (encounteredClasses != nil) {
            @synchronized(PSCExampleManager.class) {
                [classes addObject:class];
                [intermediaryClasses addObjectsFromArray:encounteredClasses];
            }
        }
    });
    // We're just interested in the leaf example classes, and not
    // in any intermediary subclasses in the subclass chain.
    [classes removeObjectsInArray:intermediaryClasses.allObjects];
    free(classList);
    return classes;
}

@end

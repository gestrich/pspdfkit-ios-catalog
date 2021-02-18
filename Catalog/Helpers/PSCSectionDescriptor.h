//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import <UIKit/UIKit.h>

@class PSCContent;

NS_ASSUME_NONNULL_BEGIN

/// Simple model class to describe static section.
@interface PSCSectionDescriptor : NSObject

+ (instancetype)sectionWithTitle:(nullable NSString *)title footer:(nullable NSString *)footer;
- (void)addContent:(PSCContent *)contentDescriptor;

@property (nonatomic, copy) NSArray<PSCContent *> *contentDescriptors;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *footer;
@property (nonatomic, nullable) UIView *headerView;
@property (nonatomic) BOOL isCollapsed;

@end

NS_ASSUME_NONNULL_END

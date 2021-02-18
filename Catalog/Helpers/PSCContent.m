//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCContent.h"

@implementation PSCContent

+ (instancetype)contentWithTitle:(nullable NSString *)title image:(nullable UIImage *)image description:(nullable NSString *)description {
    return [[self alloc] initWithTitle:title image:image description:description isSectionHeader:NO];
}

+ (instancetype)sectionHeaderContentWithTitle:(nullable NSString *)title description:(nullable NSString *)description {
    return [[self alloc] initWithTitle:title image:nil description:description isSectionHeader:YES];
}

- (instancetype)initWithTitle:(nullable NSString *)title image:(nullable UIImage *)image description:(nullable NSString *)description isSectionHeader:(BOOL)isSectionHeader {
    if ((self = [super init])) {
        _title = [title copy];
        _image = image;
        _contentDescription = [description copy];
        _isSectionHeader = isSectionHeader;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p title:%@ description:%@>", self.class, (void *)self, self.title, self.contentDescription];
}

@end

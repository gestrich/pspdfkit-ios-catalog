//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import <Foundation/Foundation.h>
#import <PSPDFKit/PSPDFKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString *PSCAssetName NS_EXTENSIBLE_STRING_ENUM NS_SWIFT_NAME(AssetName);

FOUNDATION_EXTERN PSCAssetName const PSCAssetNameQuickStart;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNameAbout;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNameMagazine;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNameWeb;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNameJKHF;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNameAnnualReport;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNameTeacher;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNameStudent;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNameHideRevealAreaExample;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNameCosmicContextForLife;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNamePsychologyResearch;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNameConstructionPlan;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNameFlightManual;
FOUNDATION_EXTERN PSCAssetName const PSCAssetNamePassengerList;

NS_SWIFT_NAME(AssetLoader)
@interface PSCAssetLoader : NSObject

+ (NSURL *)assetURLWithName:(PSCAssetName)name;

/// Load sample file with file `name`.
+ (PSPDFDocument *)documentWithName:(PSCAssetName)name;

/// Loads a document and copies it to a temp directory so it can be written.
+ (PSPDFDocument *)writableDocumentWithName:(PSCAssetName)name overrideIfExists:(BOOL)overrideIfExists;

/// Generates a test PDF with `string` as content.
+ (PSPDFDocument *)temporaryDocumentWithString:(nullable PSCAssetName)string;

@end

NS_ASSUME_NONNULL_END

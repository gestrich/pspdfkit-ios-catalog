//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCAssetLoader.h"
#import "PSCFileHelper.h"

NSString *const PSCAssetNameQuickStart = @"PSPDFKit 10 QuickStart Guide.pdf";
NSString *const PSCAssetNameAbout = @"About PSPDFKit.pdf";
NSString *const PSCAssetNameMagazine = @"Magazine.pdf";
NSString *const PSCAssetNameWeb = @"PSPDF Web.pdf";
NSString *const PSCAssetNameJKHF = @"JKHF - Annual Report.pdf";
NSString *const PSCAssetNameAnnualReport = @"Annual Report.pdf";
NSString *const PSCAssetNameTeacher = @"PSPDFKit_Teacher.pdf";
NSString *const PSCAssetNameStudent = @"PSPDFKit_Student.pdf";
NSString *const PSCAssetNameHideRevealAreaExample = @"Hide Reveal Area Example.pdf";
NSString *const PSCAssetNameCosmicContextForLife = @"The-Cosmic-Context-for-Life.pdf";
NSString *const PSCAssetNamePsychologyResearch = @"Psychology Research.pdf";
NSString *const PSCAssetNameConstructionPlan = @"Construction-Plan.pdf";
NSString *const PSCAssetNameFlightManual = @"Flight-Manual.pdf";
NSString *const PSCAssetNamePassengerList = @"Passenger-List.pdf";

@implementation PSCAssetLoader

+ (NSURL *)assetURLWithName:(PSCAssetName)name {
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSURL *samplesURL = [bundle.resourceURL URLByAppendingPathComponent:@"Samples" isDirectory:YES];
    NSURL *assetURL = [samplesURL URLByAppendingPathComponent:name isDirectory:NO];
    NSAssert(assetURL != nil, @"Must be able to create URL.");
    return assetURL;
}

+ (PSPDFDocument *)documentWithName:(PSCAssetName)name {
    return [[PSPDFDocument alloc] initWithURL:[self assetURLWithName:name]];
}

+ (PSPDFDocument *)writableDocumentWithName:(PSCAssetName)name overrideIfExists:(BOOL)overrideIfExists {
    NSURL *URL = [self assetURLWithName:name];
    NSURL *writableURL = PSCCopyFileURLToDocumentFolderAndOverride(URL, overrideIfExists);
    PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:writableURL];
    document.annotationSaveMode = PSPDFAnnotationSaveModeEmbedded;
    return document;
}

+ (PSPDFDocument *)temporaryDocumentWithString:(PSCAssetName)string {
    NSMutableData *pdfData = [NSMutableData new];
    UIGraphicsBeginPDFContextToData(pdfData, CGRectMake(0.0, 0.0, 210.0 * 3, 297.0 * 3), @{});
    UIGraphicsBeginPDFPage();
    [string drawAtPoint:CGPointMake(20.0, 20.0) withAttributes:nil];
    UIGraphicsEndPDFContext();
    PSPDFDocument *document = [[PSPDFDocument alloc] initWithDataProviders:@[[[PSPDFDataContainerProvider alloc] initWithData:pdfData]]];
    document.title = string;
    return document;
}

@end

//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Creates a temp URL.
FOUNDATION_EXTERN NSURL *PSCTempFileURLWithPathExtension(NSString *_Nullable prefix, NSString *pathExtension) NS_SWIFT_NAME(TempFileURLWithPathExtension(prefix:pathExtension:));

/// Copies a file to the documents directory.
FOUNDATION_EXTERN NSURL *PSCCopyFileURLToDocumentFolderAndOverride(NSURL *documentURL, BOOL override) NS_SWIFT_NAME(CopyFileURLToDocumentFolder(_:override:));

/// Moves a file to the documents directory.
FOUNDATION_EXTERN NSURL *PSCMoveFileURLToDocumentFolderAndOverride(NSURL *documentURL, BOOL override) NS_SWIFT_NAME(MoveFileURLToDocumentFolder(_:override:));

/// Detects if the file is located in the app's Samples directory.
FOUNDATION_EXTERN BOOL PSCIsFileLocatedInSamplesFolder(NSURL *documentURL) NS_SWIFT_NAME(IsFileLocatedInSamplesFolder(_:));

/// Detects if the file is located in the app's Documents/Inbox directory.
FOUNDATION_EXTERN BOOL PSCIsFileLocatedInInbox(NSURL *documentURL) NS_SWIFT_NAME(IsFileLocatedInInbox(_:));

NS_ASSUME_NONNULL_END

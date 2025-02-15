//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'AESCryptoDataProviderExample.swift' for the Swift version of this example.

#import "PSCExample.h"

@interface PSCAESCryptoDataProviderExample : PSCExample
@end
@implementation PSCAESCryptoDataProviderExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"PSPDFAESCryptoDataProvider";
        self.contentDescription = @"Example how to decrypt a AES256 encrypted PDF on the fly.";
        self.category = PSCExampleCategorySecurity;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    NSURL *const samplesURL = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"Samples"];
    NSURL *const encryptedPDF = [samplesURL URLByAppendingPathComponent:@"aes-encrypted.pdf.aes"];

    // Note: For shipping apps, you need to protect this string better, making it harder for hacker to simply disassemble and receive the key from the binary. Or add an internet service that fetches the key from an SSL-API. But then there's still the slight risk of memory dumping with an attached gdb. Or screenshots. Security is never 100% perfect; but using AES makes it way harder to get the PDF. You can even combine AES and a PDF password.
    NSString *const passphrase = @"afghadöghdgdhfgöhapvuenröaoeruhföaeiruaerub";
    NSString *const salt = @"ducrXn9WaRdpaBfMjDTJVjUf3FApA6gtim0e61LeSGWV9sTxB0r26mPs59Lbcexn";

    // PSPDFKit doesn't want to keep the passphrase in memory any longer than it has to. This is the reason we use a passphrase provider.
    // For optimal results, always fetch the passphrase from secure storage (like the keychain) and never keep it in memory.
    NSString * (^const passphraseProvider)(void) = ^() {
        return passphrase;
    };

    PSPDFAESCryptoDataProvider *cryptoWrapper = [[PSPDFAESCryptoDataProvider alloc] initWithURL:encryptedPDF passphraseProvider:passphraseProvider salt:salt rounds:PSPDFDefaultPBKDFNumberOfRounds];

    PSPDFDocument *document = [[PSPDFDocument alloc] initWithDataProviders:@[cryptoWrapper]];
    document.UID = encryptedPDF.lastPathComponent; // Manually set a UID for encrypted documents.

    // `PSPDFAESCryptoDataProvider` automatically disables `useDiskCache` to restrict using the disk cache for encrypted documents.
    // If you use a custom crypto solution, don't forget to disable `useDiskCache` on your custom data provider or on the document,
    // in order to avoid leaking out encrypted data as cached images.
//     document.useDiskCache = NO;

    return [[PSPDFViewController alloc] initWithDocument:document];
}

@end

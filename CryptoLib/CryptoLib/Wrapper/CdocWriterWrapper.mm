
#import "CdocWriterWrapper.h"
#import "cdoc/CdocWriter.h"


@implementation CdocWriterWrapper

- (void)encryptFile : (NSString *)fullPath withPath: (NSString *) dataFilePath withCert: (NSData *) cert withName: (NSString *) filename {
    
    std::string encodedFullPath = std::string([fullPath UTF8String]);
    std::string encodedDataFilePath = std::string([dataFilePath UTF8String]);
    std::string encodedFilename = std::string([filename UTF8String]);
    
    const void *bytes = [cert bytes];
    NSMutableArray *ary = [NSMutableArray array];
    for (NSUInteger i = 0; i < [cert length]; i += sizeof(int8_t)) {
        int8_t elem = OSReadLittleInt(bytes, i);
        [ary addObject:[NSNumber numberWithInt:elem]];
    }
    
    std::vector<unsigned char> result;
    result.reserve(ary.count);
    for (NSNumber* bar in ary) {
        result.push_back(bar.charValue);
    }
    
    CDOCWriter cdocWriter(encodedFullPath, "http://www.w3.org/2009/xmlenc11#aes256-gcm");
    
    cdocWriter.addFile(encodedFilename, "application/octet-stream", encodedDataFilePath);
    cdocWriter.addRecipient(result);
    cdocWriter.encrypt();

    
}

@end

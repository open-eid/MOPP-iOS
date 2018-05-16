


#ifndef CdocWriter_h
#define CdocWriter_h


#endif /* CdocWriter_h */

#import <Foundation/Foundation.h>

#if __cplusplus
#import "cdoc/CdocWriter.h"
#endif
@interface CdocWriterWrapper : NSObject
- (void)encryptFile: (NSString *)fullPath withPath :(NSString *) dataFilePath withCert: (NSData *) data withName: (NSString *) filename;
@end






#import <Foundation/Foundation.h>

@interface LDAPResponse : NSObject

@property (nonatomic, copy) NSString *serialNumber;
@property (nonatomic, copy) NSArray *userCertificate;
@property (nonatomic, copy) NSArray *objectClass;
@property (nonatomic, copy) NSString *cn;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
+ (NSArray<LDAPResponse *> *)responsesWithDictionary:(NSDictionary *)dictionary;

@end

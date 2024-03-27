#import <Foundation/Foundation.h>

@interface LDAPResponse : NSObject

@property (nonatomic, copy) NSString *serialNumber;
@property (nonatomic, copy) NSArray *userCertificate;
@property (nonatomic, copy) NSArray *objectClass;
@property (nonatomic, copy) NSString *cn;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

@implementation LDAPResponse

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        if (dictionary) {
            _serialNumber = dictionary[@"serialNumber"];
            id userCertificateValue = dictionary[@"userCertificate;binary"];
            if (userCertificateValue && 
                [userCertificateValue isKindOfClass:[NSArray class]]) {
                _userCertificate = userCertificateValue;
            } else if (userCertificateValue) {
                _userCertificate = @[userCertificateValue];
            } else {
                _userCertificate = @[];
            }
            _objectClass = dictionary[@"objectClass"];
            _cn = dictionary[@"cn"];
        } else {
            _serialNumber = @"";
            _userCertificate = @[];
            _objectClass = @[];
            _cn = @"";
        }
    }
    return self;
}

+ (NSArray<LDAPResponse *> *)responsesWithDictionary:(NSDictionary *)dictionary {
    NSMutableArray<LDAPResponse *> *responses = [NSMutableArray array];
    for (id obj in [dictionary allValues]) {
        LDAPResponse *response = [[LDAPResponse alloc] initWithDictionary:obj];
        [responses addObject:response];
    }
    return [responses copy];
}

@end

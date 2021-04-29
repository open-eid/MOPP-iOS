//
//  MoppLibTests.m
//  MoppLibTests
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#import <XCTest/XCTest.h>
#import "MoppLibPinActions+Tests.h"
#import <OCMock/OCMock.h>

@interface PinVerificationTests : XCTestCase
@property (nonatomic, strong) id cardActionsManagerMock;
@property (nonatomic, strong) NSDate *birthDate;
@end

@implementation PinVerificationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
  
  self.cardActionsManagerMock = OCMClassMock([CardActionsManager class]);
  OCMStub([self.cardActionsManagerMock sharedInstance]).andReturn(self.cardActionsManagerMock);
  
  OCMStub([self.cardActionsManagerMock cardOwnerBirthDateWithSuccess:[OCMArg any] failure:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    void (^successBlock)( NSDate *date);
    
    [invocation getArgument: &successBlock atIndex: 3];
    successBlock(self.birthDate);
  });
  
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDateComponents *comp = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:[NSDate date]];
  [comp setDay:5];
  [comp setMonth:4];
  [comp setYear:1886];
  self.birthDate = [gregorian dateFromComponents:comp];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPin1SameAsVerify {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin1 pin:@"1252" andVerificationCode:@"1252" success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinMatchesVerificationCode);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {

  }];
}

- (void)testPin1Invalid1 {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin1 pin:@"0000" andVerificationCode:@"0001" success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinTooEasy);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin1Invalid2 {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin1 pin:@"1234" andVerificationCode:@"0001" success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinTooEasy);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin1TooShort {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin1 pin:@"223" andVerificationCode:@"0001" success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorIncorrectPinLength);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin1TooLong {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin1 pin:@"1122334455667" andVerificationCode:@"0001" success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorIncorrectPinLength);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin1BoundariesMin {
  NSString *newPin = @"2233";
  NSString *oldPin = @"0001";
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];

  [MoppLibPinActions verifyType:CodeTypePin1 pin:newPin andVerificationCode:oldPin success:^{
    XCTAssertTrue(YES);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(NO);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin1BoundariesMax {
  NSString *newPin = @"112233445566";
  NSString *oldPin = @"0001";
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin1 pin:newPin andVerificationCode:oldPin success:^{
    XCTAssertTrue(YES);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(NO);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin1ContainsInvalidChars {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin1 pin:@"12a34" andVerificationCode:@"0001" success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinContainsInvalidCharacters);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin1ContainsBirthYear {
  NSString *newPin = @"451886";
  NSString *oldPin = @"0001";
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin1 pin:newPin andVerificationCode:oldPin success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinTooEasy);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin1ContainsBirthDayAndMonth {
  NSString *newPin = @"9805043";
  NSString *oldPin = @"0001";
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin1 pin:newPin andVerificationCode:oldPin success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinTooEasy);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin1ContainsBirthMonthAndDay {
  NSString *newPin = @"9804053";
  NSString *oldPin = @"0001";
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin1 pin:newPin andVerificationCode:oldPin success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinTooEasy);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin2SameAsVerify {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin2 pin:@"23523" andVerificationCode:@"23523" success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinMatchesVerificationCode);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin2Invalid1 {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin2 pin:@"00000" andVerificationCode:@"00011" success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinTooEasy);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin2Invalid2 {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin2 pin:@"12345" andVerificationCode:@"00011" success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinTooEasy);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin2ContainsInvalidChars {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin2 pin:@"12a34" andVerificationCode:@"00011" success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinContainsInvalidCharacters);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin2TooShort {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin2 pin:@"1234" andVerificationCode:@"00011" success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorIncorrectPinLength);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin2TooLong {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin2 pin:@"1122334455667" andVerificationCode:@"00011" success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorIncorrectPinLength);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin2BoundariesMin {
  NSString *newPin = @"22334";
  NSString *oldPin = @"00011";
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin2 pin:newPin andVerificationCode:oldPin success:^{
    XCTAssertTrue(YES);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(NO);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin2BoundariesMax {
  
  NSString *newPin = @"112233445566";
  NSString *oldPin = @"00011";
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin2 pin:newPin andVerificationCode:oldPin success:^{
    XCTAssertTrue(YES);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(NO);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin2ContainsBirthYear {
  NSString *newPin = @"451886";
  NSString *oldPin = @"00011";
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin2 pin:newPin andVerificationCode:oldPin success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinTooEasy);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin2ContainsBirthDayAndMonth {
  NSString *newPin = @"9805043";
  NSString *oldPin = @"00011";
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin2 pin:newPin andVerificationCode:oldPin success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinTooEasy);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}

- (void)testPin2ContainsBirthMonthAndDay {
  NSString *newPin = @"9804053";
  NSString *oldPin = @"00011";
  XCTestExpectation *expectation = [self expectationWithDescription:@"Pin verified"];
  
  [MoppLibPinActions verifyType:CodeTypePin2 pin:newPin andVerificationCode:oldPin success:^{
    XCTAssertTrue(NO);
    [expectation fulfill];
    
  } failure:^(NSError *error) {
    XCTAssert(error.code == moppLibErrorPinTooEasy);
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
    
  }];
}




@end

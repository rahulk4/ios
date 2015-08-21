//
//  ShareFileOrFolderTests.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 20/8/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ShareFileOrFolder.h"

@interface ShareFileOrFolderTests : XCTestCase

@property (nonatomic) FileDto *file;
@property (nonatomic) OCSharedDto *shareDto;
@property (nonatomic) ShareFileOrFolder* sharedFileOrFolder;


@end

@implementation ShareFileOrFolderTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.sharedFileOrFolder = [ShareFileOrFolder new];
   // self.sharedFileOrFolder.delegate = self;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}



- (void)testClickOnShareLinkFromFileDto {
    // This is an example of a functional test case.
    
    
     //launch the sharing
    [self.sharedFileOrFolder clickOnShareLinkFromFileDto:true];

    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

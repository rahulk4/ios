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
@property (nonatomic, strong) AppDelegate *app;
//@property (nonatomic, strong) UIActionSheet *shareActionSheet;


@end

@interface ShareFileOrFolder (Test)

- (void)showError:(NSString *) message;

@end

@implementation ShareFileOrFolderTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    self.sharedFileOrFolder = [ShareFileOrFolder new];
    
   // self.sharedFileOrFolder.delegate = self;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    //Given-When-Then pattern
    //given
    
    //when
    
    //then
    XCTAssert(YES, @"Pass");
    
    
// The given part describes the state of the world before you begin the behavior you're specifying in this scenario. You can think of it as the pre-conditions to the test.
// The when section is that behavior that you're specifying.
//Finally the then section describes the changes you expect due to the specified behavior
    
    
}





//create fileDTO
- (FileDto *) getFileDtoToTest {
    
    FileDto * file;
    
    file.idFile = 1;
    file.filePath = @"";
    file.fileName = @"fileTest";
    file.isDirectory = 0;
    file.userId = 1;
    file.isDownload = 0;
    file.size = 100;
    //file.fileId = [rs intForColumn:@"file_id"];
    //output.date = [rs longForColumn:@"date"];
    //output.isFavorite = [rs intForColumn:@"is_favorite"];
    //output.localFolder = [UtilsUrls getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:user];
    //output.etag = [rs stringForColumn:@"etag"];
    //output.isRootFolder = [rs intForColumn:@"is_root_folder"];
    //output.isNecessaryUpdate = [rs intForColumn:@"is_necessary_update"];
    //output.sharedFileSource = [rs intForColumn:@"shared_file_source"];
    //output.permissions = [rs stringForColumn:@"permissions"];
    //output.taskIdentifier = [rs intForColumn:@"task_identifier"];
    //output.providingFileId = [rs intForColumn:@"providing_file_id"];
    
    return file;
    
}

#pragma mark ShowShareActionSheet tests

- (void)testShowShareActionSheetForFileForServerShareApiSupportedAndFileIsShared {
    
    //given
    APP_DELEGATE.activeUser.hasShareApiSupport = serverFunctionalitySupported;
    FileDto *file = [self getFileDtoToTest];
    
    file.sharedFileSource = 1; //Already shared
    
    //when
    [self.sharedFileOrFolder showShareActionSheetForFile:file];
    
    //then
    //check sheet is show
    XCTAssertNotNil(self.sharedFileOrFolder.shareActionSheet);
    
}

- (void)testShowShareActionSheetForFileForServerShareApiSupportedAndFileIsNotShared {
    
    //given
    APP_DELEGATE.activeUser.hasShareApiSupport = serverFunctionalitySupported;
    FileDto *file;
    file.sharedFileSource = 0; //No shared
    
    
    //when
    
    
    //then
    //check launch the sharing
    
}

- (void)testShowShareActionSheetForFileForServerShareApiNotCheckedAndFileIsShared {
    
    //given
    APP_DELEGATE.activeUser.hasShareApiSupport = serverFunctionalityNotChecked;
    FileDto *file;
    
    
    
    //when
    
    
    //then
    //check sheet is show
    
}

- (void)testShowShareActionSheetForFileForServerShareApiNotCheckedAndFileIsNotShared {
    
    //given
    APP_DELEGATE.activeUser.hasShareApiSupport = serverFunctionalityNotChecked;
    FileDto *file;
    
    
    
    //when
    
    
    //then
    //check launch the sharing
    
}

- (void)testShowShareActionSheetForFileForServerShareApiNotSupported {
    
    //given
    APP_DELEGATE.activeUser.hasShareApiSupport = serverFunctionalityNotSupported;
    FileDto *file;
    
    
    
    //when
    
    
    //then
    //check alert error is show
    //XCTAssertTrue();
    
}

#pragma mark Alert View Tests

- (void)testShowError {
    // This is an example of a functional test case.
    
    //XCTAssert([self.sharedFileOrFolder showError:@"message"], @"alert not show");
}




#pragma mark  Tests

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

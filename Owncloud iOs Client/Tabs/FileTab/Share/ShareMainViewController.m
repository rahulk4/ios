//
//  ShareMainViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/8/15.
//

/*
 Copyright (C) 2015, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ShareMainViewController.h"
#import "ManageFilesDB.h"
#import "UtilsUrls.h"
#import "UserDto.h"
#import "OCSharedDto.h"
#import "Owncloud_iOs_Client-Swift.h"
#import "FileNameUtils.h"
#import "UIColor+Constants.h"
#import "OCNavigationController.h"
#import "ManageUsersDB.h"
#import "EditAccountViewController.h"
#import "Customization.h"
#import "ShareSearchUserViewController.h"
#import "ManageSharesDB.h"
#import "CapabilitiesDto.h"
#import "ManageCapabilitiesDB.h"

//tools
#define standardDelay 0.2
#define animationsDelay 0.5
#define largeDelay 1.0

//Xib
#define shareMainViewNibName @"ShareViewController"

//Cells and Sections
#define shareFileCellIdentifier @"ShareFileIdentifier"
#define shareFileCellNib @"ShareFileCell"
#define shareLinkOptionIdentifer @"ShareLinkOptionIdentifier"
#define shareLinkOptionNib @"ShareLinkOptionCell"
#define shareLinkHeaderIdentifier @"ShareLinkHeaderIdentifier"
#define shareLinkHeaderNib @"ShareLinkHeaderCell"
#define shareLinkButtonIdentifier @"ShareLinkButtonIdentifier"
#define shareLinkButtonNib @"ShareLinkButtonCell"
#define shareUserCellIdentifier @"ShareUserCellIdentifier"
#define shareUserCellNib @"ShareUserCell"
#define heighOfFileDetailrow 120.0
#define heightOfShareLinkOptionRow 55.0
#define heightOfShareLinkButtonRow 40.0
#define heightOfShareLinkHeader 45.0
#define heightOfShareWithUserRow 55.0
#define shareTableViewSectionsNumber  3

//Nº of Rows
#define optionsShownWithShareLinkEnable 3
#define optionsShownWithShareLinkDisable 0

//Date server format
#define dateServerFormat @"YYYY-MM-dd"

//alert share password
#define password_alert_view_tag 601

@interface ShareMainViewController ()

@property (nonatomic, strong) FileDto* sharedItem;
@property (nonatomic, strong) OCSharedDto *updatedOCShare;
@property (nonatomic) NSInteger optionsShownWithShareLink;
@property (nonatomic) BOOL isShareLinkEnabled;
@property (nonatomic) BOOL isPasswordProtectEnabled;
@property (nonatomic) BOOL isExpirationDateEnabled;
@property (nonatomic, strong) NSString* sharedToken;
@property (nonatomic, strong) ShareFileOrFolder* sharedFileOrFolder;
@property (nonatomic, strong) MBProgressHUD* loadingView;
@property (nonatomic, strong) UIAlertView *passwordView;
@property (nonatomic, strong) UIActivityViewController *activityView;
@property (nonatomic, strong) EditAccountViewController *resolveCredentialErrorViewController;
@property (nonatomic, strong) UIPopoverController* activityPopoverController;
@property (nonatomic, strong) NSMutableArray *sharedUsersOrGroups;

@end


@implementation ShareMainViewController


- (id) initWithFileDto:(FileDto *)fileDto {
    
    if ((self = [super initWithNibName:shareMainViewNibName bundle:nil]))
    {
        self.sharedItem = fileDto;
        self.optionsShownWithShareLink = 0;
        self.isShareLinkEnabled = false;
        self.isPasswordProtectEnabled = false;
        self.isExpirationDateEnabled = false;
        self.sharedUsersOrGroups = [NSMutableArray new];
        
    }
    
    return self;
}

- (void) viewDidLoad{
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setStyleView];
    
    [self checkSharedStatusOFile];
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}


#pragma mark - Accessory alert views

- (void) showPasswordView {
    
    if (self.passwordView != nil) {
        self.passwordView = nil;
    }
    
    self.passwordView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"shared_link_protected_title", nil)
                                                  message:nil delegate:self
                                        cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                        otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
    
    self.passwordView.tag = password_alert_view_tag;
    self.passwordView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [self.passwordView textFieldAtIndex:0].delegate = self;
    [[self.passwordView textFieldAtIndex:0] setAutocorrectionType:UITextAutocorrectionTypeNo];
    [[self.passwordView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [[self.passwordView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDefault];
    [[self.passwordView textFieldAtIndex:0] setKeyboardAppearance:UIKeyboardAppearanceLight];
    [[self.passwordView textFieldAtIndex:0] setSecureTextEntry:true];
    
    [self.passwordView show];
}

#pragma mark - Date Picker methods

- (void) launchDatePicker{
    
    static CGFloat controlToolBarHeight = 44.0;
    static CGFloat datePickerViewYPosition = 40.0;
    static CGFloat datePickerViewHeight = 300.0;
    static CGFloat pickerViewHeight = 250.0;
    static CGFloat deltaSpacerWidthiPad = 150.0;
 
    
    self.datePickerContainerView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.datePickerContainerView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.datePickerContainerView];
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [recognizer setNumberOfTapsRequired:1];
    recognizer.delegate = self;
    recognizer.cancelsTouchesInView = true;
    [self.datePickerContainerView addGestureRecognizer:recognizer];

    UIToolbar *controlToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, controlToolBarHeight)];
    [controlToolbar sizeToFit];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dateSelected:)];
    
    UIBarButtonItem *spacer;
    
    if (IS_IPHONE) {
         spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    }else{
         spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
         CGFloat width = self.view.frame.size.width - deltaSpacerWidthiPad;
         spacer.width = width;
    }
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeDatePicker)];
    

    [controlToolbar setItems:[NSArray arrayWithObjects:cancelButton, spacer, doneButton, nil] animated:NO];
    
    if (self.datePickerView == nil) {
        self.datePickerView = [[UIDatePicker alloc] init];
        self.datePickerView.datePickerMode = UIDatePickerModeDate;
        
        NSDateComponents *deltaComps = [NSDateComponents new];
        [deltaComps setDay:1];
        NSDate *tomorrow = [[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:[NSDate date] options:0];
        
        self.datePickerView.minimumDate = tomorrow;
    }
    
    [self.datePickerView setFrame:CGRectMake(0, datePickerViewYPosition, self.view.frame.size.width, datePickerViewHeight)];
    
    if (!self.pickerView) {
        self.pickerView = [[UIView alloc] initWithFrame:self.datePickerView.frame];
    } else {
        [self.pickerView setHidden:NO];
    }
    
    
    [self.pickerView setFrame:CGRectMake(0,
                                         self.view.frame.size.height,
                                         self.view.frame.size.width,
                                         pickerViewHeight)];
    
    [self.pickerView setBackgroundColor: [UIColor whiteColor]];
    [self.pickerView addSubview: controlToolbar];
    [self.pickerView addSubview: self.datePickerView];
    [self.datePickerView setHidden: false];
    
    [self.datePickerContainerView addSubview:self.pickerView];
    
    [UIView animateWithDuration:animationsDelay
                     animations:^{
                         [self.pickerView setFrame:CGRectMake(0,
                                                              self.view.frame.size.height - self.pickerView.frame.size.height,
                                                              self.view.frame.size.width,
                                                              pickerViewHeight)];
                     }
                     completion:nil];
    
}


- (void) dateSelected:(UIBarButtonItem *)sender{
    
    [self closeDatePicker];
    
    NSString *dateString = [self convertDateInServerFormat:self.datePickerView.date];
    
    [self updateSharedLinkWithPassword:nil andExpirationDate:dateString];
    
}

- (void) closeDatePicker {
    [UIView animateWithDuration:animationsDelay animations:^{
        [self.pickerView setFrame:CGRectMake(self.pickerView.frame.origin.x,
                                         self.view.frame.size.height,
                                         self.pickerView.frame.size.width,
                                         self.pickerView.frame.size.height)];
    } completion:^(BOOL finished) {
        [self.datePickerContainerView removeFromSuperview];
    }];
    
    [self updateInterfaceWithShareLinkStatus];
    
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    [self.datePickerContainerView removeGestureRecognizer:sender];
    [self closeDatePicker];
}

- (NSString *) converDateInCorrectFormat:(NSDate *) date {
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSLocale *locale = [NSLocale currentLocale];
    [dateFormatter setLocale:locale];

    return [dateFormatter stringFromDate:date];
}

- (NSString *) convertDateInServerFormat:(NSDate *)date {
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    
    [dateFormatter setDateFormat:dateServerFormat];
    
    return [dateFormatter stringFromDate:date];
}


#pragma mark - Style Methods

- (void) setStyleView {
    
    self.navigationItem.title = NSLocalizedString(@"share_link_long_press", nil);
    [self setBarButtonStyle];
    
}

- (void) setBarButtonStyle {

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didSelectCloseView)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
}

- (void) reloadView {
    
    if (self.isShareLinkEnabled == true){
        self.optionsShownWithShareLink = optionsShownWithShareLinkEnable;
    }else{
        self.optionsShownWithShareLink = optionsShownWithShareLinkDisable;
        self.isPasswordProtectEnabled = false;
        self.isExpirationDateEnabled = false;
    }
    
    [self.shareTableView reloadData];
}

#pragma mark - Action Methods

- (void) updateInterfaceWithShareLinkStatus {
    
    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    if (self.sharedItem.sharedFileSource > 0) {
        
        self.isShareLinkEnabled = true;
        
        self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
        
        if (self.sharedFileOrFolder == nil) {
            self.sharedFileOrFolder = [ShareFileOrFolder new];
            self.sharedFileOrFolder.delegate = self;
        }
        
        self.updatedOCShare = [self.sharedFileOrFolder getTheOCShareByFileDto:self.sharedItem];
        
        if (![ self.updatedOCShare.shareWith isEqualToString:@""] && ![ self.updatedOCShare.shareWith isEqualToString:@"NULL"]  &&  self.updatedOCShare.shareType == shareTypeLink) {
            self.isPasswordProtectEnabled = true;
        }else{
            self.isPasswordProtectEnabled = false;
        }
        
        if (self.updatedOCShare.expirationDate == 0.0) {
            self.isExpirationDateEnabled = false;
        }else {
            self.isExpirationDateEnabled = true;
        }
        
        
    }else{
        self.isShareLinkEnabled = false;
    }
    
    [self checkForShareWithUsersOrGroups];
    
    [self reloadView];
    
}

- (void) checkForShareWithUsersOrGroups {
    
    NSString *path = [NSString stringWithFormat:@"/%@%@", [UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser], self.sharedItem.fileName];
    
    NSArray *sharesWith = [ManageSharesDB getSharesFromUserAndGroupByPath:path];
    
    DLog(@"SharesWith: %@", sharesWith);
    
    [self.sharedUsersOrGroups removeAllObjects];
    
    for (OCSharedDto *shareWith in sharesWith) {
        if (shareWith.shareType == 0 || shareWith.shareType == 1) {
            [self.sharedUsersOrGroups addObject:shareWith];
        }
    }
}

- (void) didSelectCloseView {
    
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void) sharedLinkSwithValueChanged: (UISwitch*)sender {
    
    if (APP_DELEGATE.activeUser.hasCapabilitiesSupport && APP_DELEGATE.activeUser.capabilitiesDto) {
        CapabilitiesDto *cap = APP_DELEGATE.activeUser.capabilitiesDto;
        
        if (!cap.isFilesSharingShareLinkEnabled) {
            sender.on = false;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not_share_link_enabled_capabilities", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }
    }
    
    self.isShareLinkEnabled = sender.on;
    
    if (self.isShareLinkEnabled) {
        [self getShareLinkView];
    } else {
        [self unShareByLink];
    }
}


- (void) passwordProtectedSwithValueChanged:(UISwitch*) sender{
    
     if (self.isPasswordProtectEnabled){

        if (APP_DELEGATE.activeUser.hasCapabilitiesSupport) {
            CapabilitiesDto *cap = APP_DELEGATE.activeUser.capabilitiesDto;
            
            if (cap.isFilesSharingPasswordEnforcedEnabled) {
                //not remove, is enforced password
                sender.on = true;
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"shared_link_cannot_remove_password", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [alertView show];
                return;
            }
        }
        
        //Remove password Protected
        [self updateSharedLinkWithPassword:@"" andExpirationDate:nil];
         
     } else {
         //Update with password protected
         [self showPasswordView];
     }
}

- (void) expirationTimeSwithValueChanged:(UISwitch*) sender{
    
    if (self.isExpirationDateEnabled) {
        if (APP_DELEGATE.activeUser.hasCapabilitiesSupport) {
            CapabilitiesDto *cap = APP_DELEGATE.activeUser.capabilitiesDto;
            
            if (cap.isFilesSharingExpireDateEnforceEnabled) {
                //not remove, is enforced expiration date
                sender.on = true;
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"shared_link_cannot_remove_expiration_date", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [alertView show];
                return;
            }
        }
        
        //Remove expiration date
        [self updateSharedLinkWithPassword:nil andExpirationDate:@""];
        
    } else {
        //Update with expiration date
        [self launchDatePicker];
    }
    
}

#pragma mark - Actions with ShareFileOrFolder class

- (void) getShareLinkView {
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    if (IS_IPHONE) {
        self.sharedFileOrFolder.viewToShow = self.view;
        self.sharedFileOrFolder.parentViewController = self;
    }else{
        self.sharedFileOrFolder.viewToShow = self.view;
        self.sharedFileOrFolder.parentViewController = self;
        self.sharedFileOrFolder.parentView = self.view;
    }
    
    if (self.sharedItem.sharedFileSource > 0){
        self.sharedFileOrFolder.file = self.sharedItem;
        [self.sharedFileOrFolder clickOnShareLinkFromFileDto:true];
    }else{
        [self.sharedFileOrFolder showShareActionSheetForFile:self.sharedItem];
    }
}

- (void) unShareByLink {
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    OCSharedDto *ocShare = [self.sharedFileOrFolder getTheOCShareByFileDto:self.sharedItem];
    
    if (ocShare != nil) {
        [self.sharedFileOrFolder unshareTheFile:ocShare];
    }
    
}

- (void) unShareWith:(OCSharedDto *) share{
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    [self.sharedFileOrFolder unshareTheFile:share];
    
}

- (void) updateSharedLinkWithPassword:(NSString*) password andExpirationDate:(NSString*)expirationDate {
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    OCSharedDto *ocShare = [self.sharedFileOrFolder getTheOCShareByFileDto:self.sharedItem];

    [self.sharedFileOrFolder updateShareLink:ocShare withPassword:password andExpirationTime:expirationDate];
    
}

- (void) checkSharedStatusOFile {
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    [self.sharedFileOrFolder checkSharedStatusOfFile:self.sharedItem];
    
}

#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    return YES;
}

#pragma mark - UIAlertView delegate methods


- (void) alertView: (UIAlertView *) alertView willDismissWithButtonIndex: (NSInteger) buttonIndex
{
    
    if( buttonIndex == 1 ){
        //Update share item with password
        
        NSString* password = [alertView textFieldAtIndex:0].text;
        [self initLoading];
        [self updateSharedLinkWithPassword:password andExpirationDate:nil];
        
    }else if (buttonIndex == 0) {
        //Cancel
        [self reloadView];
        
    }else {
        //Nothing
    }

}


- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    BOOL output = YES;
    if (alertView.tag == password_alert_view_tag) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if ([textField.text length] == 0){
            output = NO;
        }
    }

    return output;
}


#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return shareTableViewSectionsNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    }else if (section == 1){
        if (self.sharedUsersOrGroups.count == 0) {
           return self.sharedUsersOrGroups.count + 2;
        }else{
           return self.sharedUsersOrGroups.count + 1;
        }
        
    }else{
        return self.optionsShownWithShareLink;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (indexPath.section == 0) {
        
        ShareFileCell* shareFileCell = (ShareFileCell*)[tableView dequeueReusableCellWithIdentifier:shareFileCellIdentifier];
        
        if (shareFileCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareFileCellNib owner:self options:nil];
            shareFileCell = (ShareFileCell *)[topLevelObjects objectAtIndex:0];
        }
        
        NSString *itemName = [self.sharedItem.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        shareFileCell.fileName.hidden = self.sharedItem.isDirectory;
        shareFileCell.fileSize.hidden = self.sharedItem.isDirectory;
        shareFileCell.folderName.hidden = !self.sharedItem.isDirectory;
        
        if (self.sharedItem.isDirectory == true) {
            shareFileCell.fileImage.image = [UIImage imageNamed:@"folder_icon"];
            shareFileCell.folderName.text = @"";
            //Remove the last character (folderName/ -> folderName)
            shareFileCell.folderName.text = [itemName substringToIndex:[itemName length]-1];
            
        }else{
            shareFileCell.fileImage.image = [UIImage imageNamed:[FileNameUtils getTheNameOfTheImagePreviewOfFileName:[self.sharedItem.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            shareFileCell.fileSize.text = [NSByteCountFormatter stringFromByteCount:[NSNumber numberWithLong:self.sharedItem.size].longLongValue countStyle:NSByteCountFormatterCountStyleMemory];
            shareFileCell.fileName.text = itemName;
        }
        
        cell = shareFileCell;
        
    } else if (indexPath.section == 1) {
        
        if (indexPath.row == 0 && self.sharedUsersOrGroups.count == 0){
            
            ShareUserCell* shareUserCell = (ShareUserCell*)[tableView dequeueReusableCellWithIdentifier:shareUserCellIdentifier];
            
            if (shareUserCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareUserCellNib owner:self options:nil];
                shareUserCell = (ShareUserCell *)[topLevelObjects objectAtIndex:0];
            }
            
            NSString *name = NSLocalizedString(@"not_share_with_users_yet", nil);
            
            shareUserCell.itemName.text = name;
            
            shareUserCell.selectionStyle = UITableViewCellEditingStyleNone;
            
            cell = shareUserCell;
            
        } else if ((indexPath.row == 1 && self.sharedUsersOrGroups.count == 0) || (indexPath.row == self.sharedUsersOrGroups.count)){
            
            ShareLinkButtonCell *shareLinkButtonCell = [tableView dequeueReusableCellWithIdentifier:shareLinkButtonIdentifier];
            
            if (shareLinkButtonCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkButtonNib owner:self options:nil];
                shareLinkButtonCell = (ShareLinkButtonCell *)[topLevelObjects objectAtIndex:0];
            }
            
            shareLinkButtonCell.backgroundColor = [UIColor colorOfLoginButtonBackground];
            shareLinkButtonCell.titleButton.textColor = [UIColor whiteColor];
            shareLinkButtonCell.titleButton.text = NSLocalizedString(@"add_user_or_group_title", nil);
            
            cell = shareLinkButtonCell;
            
        }else{
            
            ShareUserCell* shareUserCell = (ShareUserCell*)[tableView dequeueReusableCellWithIdentifier:shareUserCellIdentifier];
            
            if (shareUserCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareUserCellNib owner:self options:nil];
                shareUserCell = (ShareUserCell *)[topLevelObjects objectAtIndex:0];
            }
            
            
            OCSharedDto *shareWith = [self.sharedUsersOrGroups objectAtIndex:indexPath.row];
            
            NSString *name;
            
            if (shareWith.shareType == shareTypeGroup) {
                name = [NSString stringWithFormat:@"%@ (%@)",shareWith.shareWith, NSLocalizedString(@"share_user_group_indicator", nil)];
            } else {
                name = shareWith.shareWithDisplayName;
            }
            
            shareUserCell.itemName.text = name;
            
            shareUserCell.selectionStyle = UITableViewCellEditingStyleNone;
            
            cell = shareUserCell;
            
        }
        
    }else {
        
        if (indexPath.row == 2) {
            
            ShareLinkButtonCell *shareLinkButtonCell = [tableView dequeueReusableCellWithIdentifier:shareLinkButtonIdentifier];
            
            if (shareLinkButtonCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkButtonNib owner:self options:nil];
                shareLinkButtonCell = (ShareLinkButtonCell *)[topLevelObjects objectAtIndex:0];
            }
            
            shareLinkButtonCell.backgroundColor = [UIColor colorOfLoginButtonBackground];
            shareLinkButtonCell.titleButton.textColor = [UIColor whiteColor];
            shareLinkButtonCell.titleButton.text = NSLocalizedString(@"get_share_link", nil);
            
            cell = shareLinkButtonCell;
            
            
        } else {
            
            ShareLinkOptionCell* shareLinkOptionCell = [tableView dequeueReusableCellWithIdentifier:shareLinkOptionIdentifer];
            
            if (shareLinkOptionCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkOptionNib owner:self options:nil];
                shareLinkOptionCell = (ShareLinkOptionCell *)[topLevelObjects objectAtIndex:0];
            }
            
            switch (indexPath.row) {
                case 0:
                    shareLinkOptionCell.optionName.text = NSLocalizedString(@"set_expiration_time", nil);
                    
                    if (self.isExpirationDateEnabled == true) {
                        shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                        shareLinkOptionCell.optionDetail.textColor = [UIColor blackColor];
                        shareLinkOptionCell.optionDetail.text = [self converDateInCorrectFormat:[NSDate dateWithTimeIntervalSince1970: self.updatedOCShare.expirationDate]];
                    }else{
                        shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                        shareLinkOptionCell.optionDetail.textColor = [UIColor grayColor];
                        shareLinkOptionCell.optionDetail.text = @"";
                    }
                    [shareLinkOptionCell.optionSwith setOn:self.isExpirationDateEnabled animated:false];
                    
                    [shareLinkOptionCell.optionSwith addTarget:self action:@selector(expirationTimeSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
                    
                    break;
                case 1:
                    shareLinkOptionCell.optionName.text = NSLocalizedString(@"password_protect", nil);
                    
                    if (self.isPasswordProtectEnabled == true) {
                        shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                        shareLinkOptionCell.optionDetail.textColor = [UIColor blackColor];
                        shareLinkOptionCell.optionDetail.text = @"Secured";
                    } else {
                        shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                        shareLinkOptionCell.optionDetail.textColor = [UIColor grayColor];
                        shareLinkOptionCell.optionDetail.text = @"";
                    }
                    [shareLinkOptionCell.optionSwith setOn:self.isPasswordProtectEnabled animated:false];
                    
                    [shareLinkOptionCell.optionSwith addTarget:self action:@selector(passwordProtectedSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
                    
                    break;
                    
                default:
                    //Not expected
                    DLog(@"Not expected");
                    break;
            }
            
            cell = shareLinkOptionCell;
            
        }
    }
    
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = 0.0;
    
    if (indexPath.section == 0) {
        
        height = heighOfFileDetailrow;
        
    }else if (indexPath.section == 1){
        
        if (indexPath.row == 0 && self.sharedUsersOrGroups.count == 0){
            height = heightOfShareWithUserRow;
        }else if ((indexPath.row == 1 && self.sharedUsersOrGroups.count == 0) || (indexPath.row == self.sharedUsersOrGroups.count)){
            height = heightOfShareLinkButtonRow;
        }else{
            height = heightOfShareWithUserRow;
        }
        
    }else{
        
        if (indexPath.row == 2) {
            height = heightOfShareLinkButtonRow;
        }else{
            height = heightOfShareLinkOptionRow;
        }

    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = 10.0;
    
    if (section == 1 || section == 2) {
        height = heightOfShareLinkHeader;
    }
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.shareTableView.frame.size.width, 1)];
    
    
    if (section == 1 || section == 2) {
        
        ShareLinkHeaderCell* shareLinkHeaderCell = [tableView dequeueReusableCellWithIdentifier:shareLinkHeaderIdentifier];
        
        if (shareLinkHeaderCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkHeaderNib owner:self options:nil];
            shareLinkHeaderCell = (ShareLinkHeaderCell *)[topLevelObjects objectAtIndex:0];
        }
        
        if (section == 1) {
            shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"share_with_users_or_groups", nil);
            shareLinkHeaderCell.switchSection.hidden = true;
        }else{
            shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"share_link_title", nil);
            [shareLinkHeaderCell.switchSection setOn:self.isShareLinkEnabled animated:false];
            [shareLinkHeaderCell.switchSection addTarget:self action:@selector(sharedLinkSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
        
        
        headerView = shareLinkHeaderCell.contentView;
        
    }
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    if ((indexPath.section == 1) && ((indexPath.row == 1 && self.sharedUsersOrGroups.count == 0) || (indexPath.row == self.sharedUsersOrGroups.count))) {
        
        //Check if the server has Sharee support
        if (APP_DELEGATE.activeUser.hasShareeApiSupport == serverFunctionalitySupported) {
            ShareSearchUserViewController *ssuvc = [[ShareSearchUserViewController alloc] initWithNibName:@"ShareSearchUserViewController" bundle:nil];
            ssuvc.shareFileDto = self.sharedItem;
            [ssuvc setSelectedItems:self.sharedUsersOrGroups];
            self.activityView = nil;
            [self.navigationController pushViewController:ssuvc animated:true];
        }else{
            [self showErrorWithTitle:NSLocalizedString(@"not_sharee_api_supported", nil)];
            
        }
        
    }
    
    if (indexPath.section == 2 && indexPath.row == 0 && self.isExpirationDateEnabled == true){
        //Change expiration time
        [self launchDatePicker];
    }
    
    if (indexPath.section == 2 && indexPath.row == 1 && self.isPasswordProtectEnabled == true) {
        //Change the password
        [self showPasswordView];
    }
    
    if (indexPath.section == 2 && indexPath.row == 2) {
        [self getShareLinkView];
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 1 && indexPath.row != self.sharedUsersOrGroups.count) {
        return true;
    }
    
    return false;
}



- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        OCSharedDto *shareWith = [self.sharedUsersOrGroups objectAtIndex:indexPath.row];
        
        [self unShareWith:shareWith];
        
    }
}


#pragma mark - ShareFileOrFolder Delegate Methods

- (void) initLoading {

    if (self.loadingView == nil) {
        self.loadingView = [[MBProgressHUD alloc]initWithWindow:[UIApplication sharedApplication].keyWindow];
        self.loadingView.delegate = self;
    }
        
    [self.view addSubview:self.loadingView];
    
    self.loadingView.labelText = NSLocalizedString(@"loading", nil);
    self.loadingView.dimBackground = false;
    
    [self.loadingView show:true];
    
    self.view.userInteractionEnabled = false;
    self.navigationController.navigationBar.userInteractionEnabled = false;
    self.view.window.userInteractionEnabled = false;

}

- (void) endLoading {
    
    if (APP_DELEGATE.isLoadingVisible == false) {
        [self.loadingView removeFromSuperview];
        
        self.view.userInteractionEnabled = true;
        self.navigationController.navigationBar.userInteractionEnabled = true;
        self.view.window.userInteractionEnabled = true;
        
    }
}

- (void) errorLogin {
    
     [self endLoading];
    
     [self performSelector:@selector(showEditAccount) withObject:nil afterDelay:animationsDelay];
    
     [self performSelector:@selector(showErrorAccount) withObject:nil afterDelay:largeDelay];
   
}

- (void) finishShareWithStatus:(BOOL)successful andWithOptions:(UIActivityViewController*) activityView{
    
    if (successful == true) {
         self.activityView = activityView;
         [self checkSharedStatusOFile];
        
    }else{
       [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];
    }
}

- (void) finishUnShareWithStatus:(BOOL)successful {
    
    if (successful == true) {
        self.activityView = nil;
        [self checkSharedStatusOFile];
    }else{
        [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];
    }
    
}

- (void) finishUpdateShareWithStatus:(BOOL)successful {
    
    [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];
    
}

- (void) finishCheckSharedStatusOfFile:(BOOL)successful {
    
    if (successful == true && self.activityView != nil) {
        [self updateInterfaceWithShareLinkStatus];
        [self performSelector:@selector(presentShareOptions) withObject:nil afterDelay:standardDelay];
    }else{
        [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];
    }
}


- (void) presentShareOptions{
    
    if (IS_IPHONE) {
        [self presentViewController:self.activityView animated:true completion:nil];
        [self performSelector:@selector(reloadView) withObject:nil afterDelay:standardDelay];
    }else{
        [self reloadView];
        
        self.activityPopoverController = [[UIPopoverController alloc]initWithContentViewController:self.activityView];
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:2 inSection:1];
        UITableViewCell* cell = [self.shareTableView cellForRowAtIndexPath:indexPath];
        
        [self.activityPopoverController presentPopoverFromRect:cell.frame inView:self.shareTableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:true];
    }
    
}

#pragma mark - Error Login Methods

- (void) showEditAccount {
    
#ifdef CONTAINER_APP
    
    //Edit Account
    self.resolveCredentialErrorViewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:[ManageUsersDB getActiveUser]];
    [self.resolveCredentialErrorViewController setBarForCancelForLoadingFromModal];
    
    if (IS_IPHONE) {
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:self.resolveCredentialErrorViewController];
        [self.navigationController presentViewController:navController animated:YES completion:nil];
        
    } else {
        
        OCNavigationController *navController = nil;
        navController = [[OCNavigationController alloc] initWithRootViewController:self.resolveCredentialErrorViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    }
    
#endif
    
}

- (void) showErrorAccount {
    
    if (k_is_sso_active) {
        [self showErrorWithTitle:NSLocalizedString(@"session_expired", nil)];
    }else{
        [self showErrorWithTitle:NSLocalizedString(@"error_login_message", nil)];
    }
    
}

- (void)showErrorWithTitle: (NSString *)title {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [alertView show];
    
    
}

#pragma mark - UIGestureRecognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // test if our control subview is on-screen
    if ([touch.view isDescendantOfView:self.pickerView]) {
        // we touched our control surface
        return NO;
    }
    return YES;
}

@end

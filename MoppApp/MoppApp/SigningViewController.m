//
//  SigningViewController.m
//  MoppApp
//
//  Created by Ants Käär on 11.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "SigningViewController.h"
#import <MoppLib/MoppLib.h>
#import "FileManager.h"
#import "SignedContainerTableViewController.h"

@interface SigningViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UITextField *containerNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *createContainerButton;
@property (strong, nonatomic) NSString *containerFileName;

@end

@implementation SigningViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.TabSigning];
  
  [self.containerNameTextField setDelegate:self];
  [self.containerNameTextField setPlaceholder:Localizations.SigningContainerNamePlaceholder];
  [self.createContainerButton setTitle:Localizations.SigningCreateContainerButton forState:UIControlStateNormal];
}

- (IBAction)createContainerButtonPressed:(id)sender {
  
  if ([self.containerNameTextField.text isEqualToString:@""]) {
    return;
  }
  
  self.containerFileName = [NSString stringWithFormat:@"%@.bdoc", self.containerNameTextField.text];
  [self.containerNameTextField setText:@""];
  NSString *containerPath = [[FileManager sharedInstance] filePathWithFileName:self.containerFileName];
  
  NSString *dataFilePath = [[NSBundle mainBundle] pathForResource:@"datafile" ofType:@"txt"];
  
  MoppLibContainer *moppLibContainer = [[MoppLibManager sharedInstance] createContainerWithPath:containerPath withDataFilePath:dataFilePath];
  
  MoppLibDataFile *dataFile = [moppLibContainer.dataFiles objectAtIndex:0];
  MSLog(@"datafile name: %@, file size: %ld", dataFile.fileName, dataFile.fileSize);
  
  [self.containerNameTextField resignFirstResponder];
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success" message:[NSString stringWithFormat:@"Container named \"%@\" has been created. It's now visible under \"%@\" tab.", self.containerFileName, Localizations.TabSigned] preferredStyle:UIAlertControllerStyleAlert];
  
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    [self performSegueWithIdentifier:@"SignedContainerDetailsSegue" sender:self];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}


#warning - cleanup original file after creating container.
- (void)createContainerWithDataFilePath:(NSString *)dataFilePath {
  self.containerFileName = [NSString stringWithFormat:@"%@.bdoc", [[dataFilePath lastPathComponent] stringByDeletingPathExtension]];
  NSString *containerPath = [[FileManager sharedInstance] filePathWithFileName:self.containerFileName];
  MoppLibContainer *moppLibContainer = [[MoppLibManager sharedInstance] createContainerWithPath:containerPath withDataFilePath:dataFilePath];
  
  MoppLibDataFile *dataFile = [moppLibContainer.dataFiles objectAtIndex:0];
  MSLog(@"datafile name: %@, file size: %ld", dataFile.fileName, dataFile.fileSize);
  
  [self performSegueWithIdentifier:@"SignedContainerDetailsSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  SignedContainerTableViewController *detailsViewController = [segue destinationViewController];
  detailsViewController.containerFileName = self.containerFileName;
}

- (IBAction)createTestContainerButtonPressed:(id)sender {
  NSString *containerName = [[FileManager sharedInstance] createTestBDoc];
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success" message:[NSString stringWithFormat:@"TEST container named \"%@\" has been created. It's now visible under \"%@\" tab.", containerName, Localizations.TabSigned] preferredStyle:UIAlertControllerStyleAlert];
  
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self.containerNameTextField resignFirstResponder];
  [self createContainerButtonPressed:nil];
  return YES;
}


#pragma mark - Keyboard handling.
- (void)registerForKeyboardNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)unRegisterForKeyboardNotifications {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)aNotification {
  NSDictionary *info = [aNotification userInfo];
  CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  [self setScrollViewContentInsetsWithHeight:kbSize.height];
}

- (void)keyboardWillHide:(NSNotification*)aNotification {
  [self setScrollViewContentInsetsWithHeight:0.0];
}

- (void)setScrollViewContentInsetsWithHeight:(CGFloat)height {
  UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, height, 0.0);
  self.scrollView.contentInset = contentInsets;
  self.scrollView.scrollIndicatorInsets = contentInsets;
}

@end

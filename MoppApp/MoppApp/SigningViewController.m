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

@interface SigningViewController ()

@property (weak, nonatomic) IBOutlet UITextField *containerNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *createContainerButton;

@end

@implementation SigningViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.TabSigning];
  
  [self.containerNameTextField setPlaceholder:Localizations.SigningContainerNamePlaceholder];
  [self.createContainerButton setTitle:Localizations.SigningCreateContainerButton forState:UIControlStateNormal];
}

- (IBAction)createContainerButtonPressed:(id)sender {
  
  NSString *fileName = [NSString stringWithFormat:@"%@.bdoc", self.containerNameTextField.text];
  NSString *containerPath = [[FileManager sharedInstance] filePathWithFileName:fileName];
  
  MoppLibContainer *moppLibContainer = [[MoppLibManager sharedInstance] createContainerWithPath:containerPath];
}

- (IBAction)createTestContainerButtonPressed:(id)sender {
  NSString *containerName = [[FileManager sharedInstance] createTestBDoc];
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success" message:[NSString stringWithFormat:@"TEST container named \"%@\" has been created. It's now visible under \"%@\" tab.", containerName, Localizations.TabSigned] preferredStyle:UIAlertControllerStyleAlert];
  
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

@end

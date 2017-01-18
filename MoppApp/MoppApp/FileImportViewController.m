//
//  FileImportViewController.m
//  MoppApp
//
//  Created by Ants Käär on 16.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "FileImportViewController.h"
#import "FileManager.h"
#import "ContainerCell.h"
#import "DateFormatter.h"

@interface FileImportViewController ()

@property (strong, nonatomic) NSArray *unsignedContainers;
@property (strong, nonatomic) NSArray *filteredUnsignedContainers;

@end

@implementation FileImportViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setTitle:Localizations.FileImportTitle];
  
  self.unsignedContainers = [NSArray array];
  
  UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:Localizations.ActionCancel style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)];
  [self.navigationItem setRightBarButtonItem:cancelButton];
  
  UIBarButtonItem *createContainerButton = [[UIBarButtonItem alloc] initWithTitle:Localizations.FileImportCreateContainerButton style:UIBarButtonItemStylePlain target:self action:@selector(createNewContainer)];
  [self.navigationItem setLeftBarButtonItem:createContainerButton];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localizations.FileImportTitle message:Localizations.FileImportInfo([self.dataFilePath lastPathComponent]) preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Localizations.ActionOk style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)cancelButtonPressed {
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)createNewContainer {
  NSString *containerFileName = [NSString stringWithFormat:@"%@.bdoc", [[self.dataFilePath lastPathComponent] stringByDeletingPathExtension]];
  NSString *containerPath = [[FileManager sharedInstance] filePathWithFileName:containerFileName];
  MoppLibContainer *container = [[MoppLibManager sharedInstance] createContainerWithPath:containerPath withDataFilePath:self.dataFilePath];
  
#warning - remove file
//  [[FileManager sharedInstance] removeFileWithPath:self.dataFilePath];
  
  [self.navigationController dismissViewControllerAnimated:YES completion:^{
    if (self.delegate) {
      [self.delegate openContainerDetails:container];
    }
  }];
}

- (void)reloadData {
  self.unsignedContainers = [[MoppLibManager sharedInstance] getContainersIsSigned:NO];
  self.filteredUnsignedContainers = self.unsignedContainers;
  
  [super reloadData];
}

- (void)filterContainers:(NSString *)searchString {
  if (searchString.length == 0) {
    self.filteredUnsignedContainers = self.unsignedContainers;
  } else {
    self.filteredUnsignedContainers = [self.unsignedContainers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.fileName contains[c] %@", searchString]];
  }
  [super filterContainers:searchString];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.filteredUnsignedContainers.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  ContainerCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ContainerCell class]) forIndexPath:indexPath];
  
  MoppLibContainer *container = [self.filteredUnsignedContainers objectAtIndex:indexPath.row];
  
  [cell.titleLabel setText:container.fileName];
  [cell.dateLabel setText:[[DateFormatter sharedInstance] dateToRelativeString:[container.fileAttributes fileCreationDate]]];
  
  return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  MoppLibContainer *container = [self.filteredUnsignedContainers objectAtIndex:indexPath.row];
  [[MoppLibManager sharedInstance] addFileToContainerWithPath:container.filePath withDataFilePath:self.dataFilePath];
  [[FileManager sharedInstance] removeFileWithPath:self.dataFilePath];
  
  [self.navigationController dismissViewControllerAnimated:YES completion:^{
    if (self.delegate) {
      [self.delegate openContainerDetails:container];
    }
  }];
}

@end

//
//  ContainersListViewController.h
//  MoppApp
//
//  Created by Ants Käär on 16.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "BaseContainersListViewController.h"
#import "FileImportViewController.h"

@interface ContainersListViewController : BaseContainersListViewController <FileImportViewControllerDelegate>

@property (strong, nonatomic) NSString *dataFilePath;
@property (strong, nonatomic) MoppLibContainer *selectedContainer;

@end

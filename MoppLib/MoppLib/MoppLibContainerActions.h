//
//  MoppLibContainerActions.h
//  MoppLib
//
//  Created by Katrin Annuk on 03/02/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibContainer.h"
#import "MoppLibSignature.h"
#import "MoppLibConstants.h"

@interface MoppLibContainerActions : NSObject

+ (MoppLibContainerActions *)sharedInstance;

/**
 * Gets container with specified path.
 *
 * @param containerPath    Path to container.
 * @param success       Block to be called on successful completion of action. Includes container data as MoppLibContainer.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)getContainerWithPath:(NSString *)containerPath success:(ContainerBlock)success failure:(FailureBlock)failure;

/**
 * Creates container on specified path.
 *
 * @param containerPath    Path where container is created.
 * @param dataFilePath    Path to file that will be included in container.
 * @param success       Block to be called on successful completion of action. Includes container data as MoppLibContainer.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)createContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath success:(ContainerBlock)success failure:(FailureBlock)failure;

/**
 * Adds file to container.
 *
 * @param containerPath    Path to container that will be modified.
 * @param dataFilePath    Path to file that will be included in container.
 * @param success       Block to be called on successful completion of action. Includes container data as MoppLibContainer.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)addDataFileToContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath success:(ContainerBlock)success failure:(FailureBlock)failure;

/**
 * Removes file from container.
 *
 * @param containerPath    Path to container that will be modified.
 * @param dataFileIndex    Index of file that will be removed.
 * @param success       Block to be called on successful completion of action. Includes container data as MoppLibContainer.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex success:(ContainerBlock)success failure:(FailureBlock)failure;

/**
 * Gets available containers.
 *
 * @param isSigned    Set YES if you only want to get signed containers, NO if you only want containers that have not been signed by anyone.
 * @param success       Block to be called on successful completion of action. Includes container data as array of MoppLibContainer.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)getContainersIsSigned:(BOOL)isSigned success:(void(^)(NSArray *containers))success failure:(FailureBlock)failure;
#warning - this method is not very useful for third-party developer as it is. Can we change it into something more reasonable?


/**
 * Removes signature from container.
 *
 * @param moppSignature   Signature that will be removed.
 * @param containerPath    Path to container that will be modified.
 * @param success       Block to be called on successful completion of action. Includes container data as MoppLibContainer.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath success:(ContainerBlock)success failure:(FailureBlock)failure;

/**
 * Saves file included in container to specified path. required for viewing file contents.
 *
 * @param containerPath    Path to container.
 * @param fileName    Name of a file that will be saved.
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path success:(void(^)(void))success failure:(FailureBlock)failure;

/**
 * Adds signature to container.
 *
 * @param moppContainer    Container that will get new signature.
 * @param controller    UIViewController for displaying alerts if needed.
 * @param success       Block to be called on successful completion of action. Includes container data as MoppLibContainer.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)addSignature:(MoppLibContainer *)moppContainer controller:(UIViewController *)controller success:(ContainerBlock)success failure:(FailureBlock)failure;

@end

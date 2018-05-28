//
//  MoppLibContainerActions.h
//  MoppLib
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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
 * @param containerPath    Path where container is created. Must include container name and extension. Supported extensions are .bdoc and .asice
 * @param dataFilePaths    Paths to files that will be included in container.
 * @param success       Block to be called on successful completion of action. Includes container data as MoppLibContainer.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)createContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths success:(ContainerBlock)success failure:(FailureBlock)failure;

/**
 * Adds file to container.
 *
 * @param containerPath    Path to container that will be modified.
 * @param dataFilePaths    Paths to file that will be included in container.
 * @param success       Block to be called on successful completion of action. Includes container data as MoppLibContainer.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)addDataFilesToContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths success:(ContainerBlock)success failure:(FailureBlock)failure;

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
 * @param success       Block to be called on successful completion of action. Includes container data as array of MoppLibContainer.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)getContainersWithSuccess:(void(^)(NSArray *containers))success failure:(FailureBlock)failure;



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
 * Signs container with certtificates on ID card. If document has already been signed by this certificate, they will be given an opportunity to cancel signing. If they cancel, signatureWasAdded will be set to NO in success block. Updated container will be included in success block if signing is successful. Otherwise it may be missing.\n\nInternet connection is needed for signing containers. 
 *
 * @param containerPath    Path to container.
 * @param success       Block to be called on successful completion of action. Includes container data as MoppLibContainer and BOOL to indicate if signature was added.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)addSignature:(NSString *)containerPath withPin2:(NSString*)pin2 success:(void(^)(MoppLibContainer *container, BOOL signatureWasAdded))success failure:(FailureBlock)failure;



@end

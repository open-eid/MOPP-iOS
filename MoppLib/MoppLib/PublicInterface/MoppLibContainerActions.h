//
//  MoppLibContainerActions.h
//  MoppLib
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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

@class MoppLibContainer;
@class MoppLibSignature;
@class MoppLibRoleAddressData;

#if DEBUG
#define printLog(...) NSLog(__VA_ARGS__)
#else
#define printLog(...)
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (^CompletionBlock)(NSError * _Nullable error);
typedef NS_ENUM(NSInteger, SendDiagnostics);

@interface MoppLibContainerActions : NSObject

+ (NSString *)libdigidocppVersion;

/**
 * Prepares library for operations with containers. Setup must be completed before any container action is carried out. It is recommended, that you initiate setup at earliest opportunity.
 *
 * @param error      Error returned on failure.
 */
+ (BOOL)setup:(NSError **)error;

/**
 * Opens container at specified path.
 *
 * @param containerPath    Path to container.
 * @param completion       Block to be called on  of action. Includes container data as MoppLibContainer on success or on failure error.
 */
+ (void)openContainerWithPath:(NSString *)containerPath completion:(void (^)(MoppLibContainer * _Nullable container, NSError * _Nullable error))completion;

/**
 * Opens container at specified path.
 *
 * @param containerPath         Path to container.
 * @return MoppLibContainer      Successful completion of action. Includes container data as MoppLibContainer.
 * @param error                          Error when opening container.
 */
+ (MoppLibContainer * _Nullable)openContainerWithPath:(NSString *)containerPath error:(NSError **)error;

/**
 * Creates container on specified path.
 *
 * @param containerPath    Path where container is created. Must include container name and extension. Supported extensions are .bdoc and .asice
 * @param dataFilePaths    Paths to files that will be included in container.
 * @param completion       Block to be called  completion of action. On failure includes error.
 */
+ (void)createContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray<NSString*> *)dataFilePaths completion:(CompletionBlock)completion;

/**
 * Adds file to container.
 *
 * @param containerPath    Path to container that will be modified.
 * @param dataFilePaths    Paths to file that will be included in container.
 * @param completion       Block to be called  completion of action. On failure includes error.
 */
+ (void)addDataFilesToContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray<NSString*> *)dataFilePaths completion:(CompletionBlock)completion;

/**
 * Removes file from container.
 *
 * @param containerPath    Path to container that will be modified.
 * @param dataFileIndex    Index of file that will be removed.
 * @param completion       Block to be called  completion of action. On failure includes error.
 */
+ (void)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex completion:(CompletionBlock)completion;

/**
 * Removes signature from container.
 *
 * @param moppSignature   Signature that will be removed.
 * @param containerPath    Path to container that will be modified.
 * @param completion       Block to be called  completion of action. On failure includes error.
 */
+ (void)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath completion:(CompletionBlock)completion;

/**
 * Saves file included in container to specified path. required for viewing file contents.
 *
 * @param containerPath    Path to container.
 * @param fileName    Name of a file that will be saved.
 * @param completion       Block to be called  completion of action. On failure includes error.
 */
+ (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path completion:(CompletionBlock)completion;

+ (NSData * _Nullable)prepareSignature:(NSData *)cert containerPath:(NSString *)containerPath roleData:(MoppLibRoleAddressData * _Nullable)roleData sendDiagnostics:(SendDiagnostics)sendDiagnostics error:(NSError **)error;
+ (BOOL)isSignatureValid:(NSData * _Nonnull)signatureValue error:(NSError**)error;

@end

NS_ASSUME_NONNULL_END

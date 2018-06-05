//
//  MoppLibCryptoActions.h
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

//#import "LdapResponse.h"
#import "CryptoLib/OpenLdap.h"
#import "MoppLibConstants.h"
@interface MoppLibCryptoActions : NSObject
    
+ (MoppLibCryptoActions *)sharedInstance;
    
    /**
     * Search data from LDAP.
     *
     * @param identifier    LDAP search request identifier.
     * @param success       Block to be called on successful completion of action. Includes ldap respone data as LdapResponse.
     * @param failure       Block to be called when action fails. Includes error.
     */
- (void)searchLdapData:(NSString *)identifier success:(LdapBlock)success failure:(FailureBlock)failure;

    /**
     * Encrypt data and create CDOC container.
     *
     * @param fullPath      Full path of encrypted file.
     * @param dataFiles     Data files to be encrypted.
     * @param addressees    Addressees of the encrypted file.
     * @param success       Block to be called on successful completion of action. Includes ldap respone data as LdapResponse.
     * @param failure       Block to be called when action fails. Includes error.
     */
- (void)encryptData:(NSString *)fullPath withDataFiles:(NSArray*)dataFiles withAddressees:(NSArray*)addressees success:(VoidBlock)success failure:(FailureBlock)failure;
    @end


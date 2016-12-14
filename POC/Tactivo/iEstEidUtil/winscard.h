/*
 * Copyright (c) 2011 - 2012, Precise Biometrics AB
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the Precise Biometrics AB nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 *
 * $Date: 2012-05-23 08:33:11 +0200 (on, 23 maj 2012) $ $Rev: 14785 $ 
 *
 */

#ifndef _WINSCARD_H_
#define _WINSCARD_H_

#include <errno.h>
#include "wintypes.h"

#pragma mark SCARD_SCOPE_
/** @defgroup g_scope context scope
@{*/
/** The context is a user context, and any database operations are performed 
within the domain of the user.*/
#define SCARD_SCOPE_USER                    0
/** The context is that of the current terminal, and any database operations are
 performed within the domain of that terminal.  (The calling application must 
 have appropriate access permissions for any database actions.)*/
#define SCARD_SCOPE_TERMINAL                1 
/** The context is the system context, and any database operations are performed
 within the domain of the system.  (The calling application must have 
 appropriate access permissions for any database actions.)*/
#define SCARD_SCOPE_SYSTEM                  2 
/*@}*/

#pragma mark SCARD_SHARE_
/** @defgroup g_share card share
@{*/
/** This application is not willing to share this card with other applications.
*/
#define SCARD_SHARE_EXCLUSIVE               1 
/** This application is willing to share this card with other applications.*/
#define SCARD_SHARE_SHARED                  2 
/** This application demands direct control of the reader, so it is not 
available to other applications.*/
#define SCARD_SHARE_DIRECT                  3 
/*@}*/

/** @defgroup g_disposition card disposition
@{*/
/** Don't do anything special on close*/
#define SCARD_LEAVE_CARD                    0 
/** Reset the card on close*/
#define SCARD_RESET_CARD                    1 
/** Power down the card on close*/
#define SCARD_UNPOWER_CARD                  2 
/** Eject the card on close*/
#define SCARD_EJECT_CARD                    3 
/*@}*/

/** Tells the library to allocate the required memory */
#define SCARD_AUTOALLOCATE                  (DWORD)(-1) 

/** @defgroup g_card_state smart card states
@{*/
/** This value implies the driver is unaware of the current state of the reader.
*/
#define SCARD_UNKNOWN                       0 
/** This value implies there is no card in the reader.*/
#define SCARD_ABSENT                        1 
/** This value implies there is a card is present in the reader, but that it has
 not been moved into position for use.*/
#define SCARD_PRESENT                       2 
/** This value implies there is a card in the reader in position for use. The 
card is not powered.*/
#define SCARD_SWALLOWED                     3 
/** This value implies there is power is being provided to the card, but the 
Reader Driver is unaware of the mode of the card.*/
#define SCARD_POWERED                       4 
/** This value implies the card has been reset and is awaiting PTS negotiation.
*/
#define SCARD_NEGOTIABLE                    5 
/** This value implies the card has been reset and specific communication 
protocols have been established.*/
#define SCARD_SPECIFIC                      6 
/*@}*/

/** @defgroup g_reader_state reader states 
@{*/
/** The application is unaware of the current state, and would like to know.  
The use of this value results in an immediate return from state transition 
monitoring services.  This is represented by all bits set to zero.*/
#define SCARD_STATE_UNAWARE                 0x00000000  
/** The application requested that this reader be ignored.  No other bits will 
be set.*/
#define SCARD_STATE_IGNORE                  0x00000001  
/** This implies that there is a difference between the state believed by the 
application, and the state known by the Service Manager.  When this bit is set,
the application may assume a significant state change has occurred on this 
reader.*/
#define SCARD_STATE_CHANGED                 0x00000002  
/** This implies that the given reader name is not recognized by the Service 
Manager.  If this bit is set, then SCARD_STATE_CHANGED and SCARD_STATE_IGNORE 
will also be set.*/
#define SCARD_STATE_UNKNOWN                 0x00000004  
/** This implies that the actual state of this reader is not available.  If 
this bit is set, then all the following bits are clear.*/
#define SCARD_STATE_UNAVAILABLE             0x00000008  
/** This implies that there is not card in the reader.  If this bit is set, all 
the following bits will be clear.*/
#define SCARD_STATE_EMPTY                   0x00000010  
/** This implies that there is a card in the reader.*/
#define SCARD_STATE_PRESENT                 0x00000020  
/** This implies that there is a card in the reader with an ATR matching one of 
the target cards. if this bit is set, SCARD_STATE_PRESENT will also be set.  
This bit is only returned on the SCardLocateCard() service.*/
#define SCARD_STATE_ATRMATCH                0x00000040  
/** This implies that the card in the reader is allocated for exclusive use by 
another application.  If this bit is set, SCARD_STATE_PRESENT will also be set.
*/
#define SCARD_STATE_EXCLUSIVE               0x00000080  
/** This implies that the card in the reader is in use by one or more other 
applications, but may be connected to in shared mode.  If this bit is set, 
SCARD_STATE_PRESENT will also be set.*/
#define SCARD_STATE_INUSE                   0x00000100  
/** This implies that the card in the reader is unresponsive or not supported by
 the reader or software.*/
#define SCARD_STATE_MUTE                    0x00000200  
/** This implies that the card in the reader has not been powered up.*/
#define SCARD_STATE_UNPOWERED               0x00000400  
/*@}*/

/** @defgroup g_error error codes
@{*/
/** No error */
#define SCARD_S_SUCCESS                     ((DWORD)0x00000000L)
/** An internal consistency check failed.*/
#define SCARD_F_INTERNAL_ERROR              ((DWORD)0x80100001L)
/** The action was cancelled by an SCardCancel() request.*/
#define SCARD_E_CANCELLED                   ((DWORD)0x80100002L)
/** The supplied handle was invalid.*/
#define SCARD_E_INVALID_HANDLE              ((DWORD)0x80100003L)
/** One or more of the supplied parameters could not be properly interpreted.*/
#define SCARD_E_INVALID_PARAMETER           ((DWORD)0x80100004L)
/** The necessary protocols are not listed in the plist file.*/
#define SCARD_E_INVALID_TARGET              ((DWORD)0x80100005L)
/** Not enough memory available to complete this command.*/
#define SCARD_E_NO_MEMORY                   ((DWORD)0x80100006L)
/** An internal consistency timer has expired.*/
#define SCARD_F_WAITED_TOO_LONG             ((DWORD)0x80100007L)
/** The data buffer to receive returned data is too small for the returned data.
*/
#define SCARD_E_INSUFFICIENT_BUFFER         ((DWORD)0x80100008L)
/** The specified reader name is not recognized.*/
#define SCARD_E_UNKNOWN_READER              ((DWORD)0x80100009L)
/** The user-specified timeout value has expired.*/
#define SCARD_E_TIMEOUT                     ((DWORD)0x8010000AL)
/** The smart card cannot be accessed because of other connections outstanding.
*/
#define SCARD_E_SHARING_VIOLATION           ((DWORD)0x8010000BL)
/** The operation requires a Smart Card, but no Smart Card is currently in the 
device.*/
#define SCARD_E_NO_SMARTCARD                ((DWORD)0x8010000CL)
/** The specified smart card name is not recognized.*/
#define SCARD_E_UNKNOWN_CARD                ((DWORD)0x8010000DL)
/** The system could not dispose of the media in the requested manner.*/
#define SCARD_E_CANT_DISPOSE                ((DWORD)0x8010000EL)
/** The requested protocols are incompatible with the protocol currently in use
 with the smart card.*/
#define SCARD_E_PROTO_MISMATCH              ((DWORD)0x8010000FL)
/** The reader or smart card is not ready to accept commands.*/
#define SCARD_E_NOT_READY                   ((DWORD)0x80100010L)
/** One or more of the supplied parameters values could not be properly 
interpreted.*/
#define SCARD_E_INVALID_VALUE               ((DWORD)0x80100011L)
/** The action was cancelled by the system, presumably to log off or shut down.
*/
#define SCARD_E_SYSTEM_CANCELLED            ((DWORD)0x80100012L)
/** An internal communications error has been detected. This error is returned
 when iOS has forcedly terminated the underlying EASession session. */
#define SCARD_F_COMM_ERROR                  ((DWORD)0x80100013L)
/** An internal error has been detected, but the source is unknown.*/
#define SCARD_F_UNKNOWN_ERROR               ((DWORD)0x80100014L)
/** An ATR obtained from the registry is not a valid ATR string.*/
#define SCARD_E_INVALID_ATR                 ((DWORD)0x80100015L)
/** An attempt was made to end a non-existent transaction.*/
#define SCARD_E_NOT_TRANSACTED              ((DWORD)0x80100016L)
/** The specified reader is not currently available for use.*/
#define SCARD_E_READER_UNAVAILABLE          ((DWORD)0x80100017L)
/** The operation has been aborted to allow the server application to exit.*/
#define SCARD_P_SHUTDOWN                    ((DWORD)0x80100018L)
/** The PCI Receive buffer was too small.*/
#define SCARD_E_PCI_TOO_SMALL               ((DWORD)0x80100019L)
/** The reader driver does not meet minimal requirements for support.*/
#define SCARD_E_READER_UNSUPPORTED          ((DWORD)0x8010001AL)
/** The reader driver did not produce a unique reader name.*/
#define SCARD_E_DUPLICATE_READER            ((DWORD)0x8010001BL)
/** The smart card does not meet minimal requirements for support.*/
#define SCARD_E_CARD_UNSUPPORTED            ((DWORD)0x8010001CL)
/** The Smart card resource manager is not running.*/
#define SCARD_E_NO_SERVICE                  ((DWORD)0x8010001DL)
/** The Smart card resource manager has shut down.*/
#define SCARD_E_SERVICE_STOPPED             ((DWORD)0x8010001EL)
/** An unexpected card error has occurred.*/
#define SCARD_E_UNEXPECTED                  ((DWORD)0x8010001FL)
/** No Primary Provider can be found for the smart card.*/
#define SCARD_E_ICC_INSTALLATION            ((DWORD)0x80100020L)
/** The requested order of object creation is not supported.*/
#define SCARD_E_ICC_CREATEORDER             ((DWORD)0x80100021L)
/** This smart card does not support the requested feature.*/
#define SCARD_E_UNSUPPORTED_FEATURE         ((DWORD)0x80100022L)
/** The identified directory does not exist in the smart card.*/
#define SCARD_E_DIR_NOT_FOUND               ((DWORD)0x80100023L)
/** The identified file does not exist in the smart card.*/
#define SCARD_E_FILE_NOT_FOUND              ((DWORD)0x80100024L)
/** The supplied path does not represent a smart card directory.*/
#define SCARD_E_NO_DIR                      ((DWORD)0x80100025L)
/** The supplied path does not represent a smart card file.*/
#define SCARD_E_NO_FILE                     ((DWORD)0x80100026L)
/** Access is denied to this file.*/
#define SCARD_E_NO_ACCESS                   ((DWORD)0x80100027L)
/** The smartcard does not have enough memory to store the information.*/
#define SCARD_E_WRITE_TOO_MANY              ((DWORD)0x80100028L)
/** There was an error trying to set the smart card file object pointer.*/
#define SCARD_E_BAD_SEEK                    ((DWORD)0x80100029L)
/** The supplied PIN is incorrect.*/
#define SCARD_E_INVALID_CHV                 ((DWORD)0x8010002AL)
/** An unrecognized error code was returned from a layered component.*/
#define SCARD_E_UNKNOWN_RES_MNG             ((DWORD)0x8010002BL)
/** The requested certificate does not exist.*/
#define SCARD_E_NO_SUCH_CERTIFICATE         ((DWORD)0x8010002CL)
/** The requested certificate could not be obtained.*/
#define SCARD_E_CERTIFICATE_UNAVAILABLE     ((DWORD)0x8010002DL)
/** Cannot find a smart card reader.*/
#define SCARD_E_NO_READERS_AVAILABLE        ((DWORD)0x8010002EL)
/** A communications error with the smart card has been detected.  Retry the 
operation.*/
#define SCARD_E_COMM_DATA_LOST              ((DWORD)0x8010002FL)
/** The requested key container does not exist on the smart card.*/
#define SCARD_E_NO_KEY_CONTAINER            ((DWORD)0x80100030L)
/** The Smart card resource manager is too busy to complete this operation.*/
#define SCARD_E_SERVER_TOO_BUSY             ((DWORD)0x80100031L)
/** The smart card PIN cache has expired.*/
#define SCARD_E_PIN_CACHE_EXPIRED           ((DWORD)0x80100032L)
/** The smart card PIN cannot be cached.*/
#define SCARD_E_NO_PIN_CACHE                ((DWORD)0x80100033L)
/** The smart card is read only and cannot be written to.*/
#define SCARD_E_READ_ONLY_CARD              ((DWORD)0x80100034L)
/** The reader cannot communicate with the smart card, due to ATR configuration
 conflicts.*/
#define SCARD_W_UNSUPPORTED_CARD            ((DWORD)0x80100065L)
/** The smart card is not responding to a reset.*/
#define SCARD_W_UNRESPONSIVE_CARD           ((DWORD)0x80100066L)
/** Power has been removed from the smart card, so that further communication is
 not possible.*/
#define SCARD_W_UNPOWERED_CARD              ((DWORD)0x80100067L)
/** The smart card has been reset, so any shared state information is invalid.*/
#define SCARD_W_RESET_CARD                  ((DWORD)0x80100068L)
/** The smart card has been removed, so that further communication is not 
possible.*/
#define SCARD_W_REMOVED_CARD                ((DWORD)0x80100069L)
/** Access was denied because of a security violation.*/
#define SCARD_W_SECURITY_VIOLATION          ((DWORD)0x8010006AL)
/** The card cannot be accessed because the wrong PIN was presented.*/
#define SCARD_W_WRONG_CHV                   ((DWORD)0x8010006BL)
/** The card cannot be accessed because the maximum number of PIN entry attempts
 has been reached.*/
#define SCARD_W_CHV_BLOCKED                 ((DWORD)0x8010006CL)
/** The end of the smart card file has been reached.*/
#define SCARD_W_EOF                         ((DWORD)0x8010006DL)
/** The action was cancelled by the user.*/
#define SCARD_W_CANCELLED_BY_USER           ((DWORD)0x8010006EL)
/** No PIN was presented to the smart card.*/
#define SCARD_W_CARD_NOT_AUTHENTICATED      ((DWORD)0x8010006FL)
/** The requested item could not be found in the cache.*/
#define SCARD_W_CACHE_ITEM_NOT_FOUND        ((DWORD)0x80100070L)
/** The requested cache item is too old and was deleted from the cache.*/
#define SCARD_W_CACHE_ITEM_STALE            ((DWORD)0x80100071L)
/** The new cache item exceeds the maximum per-item size defined for the cache.
*/
#define SCARD_W_CACHE_ITEM_TOO_BIG          ((DWORD)0x80100072L)
/*@}*/

/** @defgroup g_protocol card protocol 
@{*/
/** There is no active protocol. */
#define SCARD_PROTOCOL_UNDEFINED            0x00000000  
/** T=0 is the active protocol. */
#define SCARD_PROTOCOL_T0                   0x00000001  
/** T=1 is the active protocol. */
#define SCARD_PROTOCOL_T1                   0x00000002  
/** Raw is the active protocol. */
#define SCARD_PROTOCOL_RAW                  0x00010000  
/** This is the mask of ISO defined transmission protocols */
#define SCARD_PROTOCOL_Tx                   (SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1)
/** Legacy mask for API compatibility */
#define SCARD_PROTOCOL_ANY                  SCARD_PROTOCOL_Tx
/*@}*/

extern uint8_t g_bgm_disable;
/** Used to disable automatic power management of the accessory and card */
/** Use DISABLE_BACKGROUND_MANAGEMENT is DEPRECATED, use SCardSetAttrib with
    SCARD_ATTR_AUTO_BACKGROUND_HANDLING to enable or disable this feature.  */
#define DISABLE_BACKGROUND_MANAGEMENT       (&g_bgm_disable)

#define SCARD_ATTR_VALUE(Class, Tag) ((((DWORD)(Class)) << 16) | ((DWORD)(Tag)))

#define SCARD_CLASS_VENDOR_INFO     1   // Vendor information definitions
#define SCARD_CLASS_COMMUNICATIONS  2   // Communication definitions
#define SCARD_CLASS_PROTOCOL        3   // Protocol definitions
#define SCARD_CLASS_POWER_MGMT      4   // Power Management definitions
#define SCARD_CLASS_SECURITY        5   // Security Assurance definitions
#define SCARD_CLASS_MECHANICAL      6   // Mechanical characteristic definitions
#define SCARD_CLASS_VENDOR_DEFINED  7   // Vendor specific definitions
#define SCARD_CLASS_IFD_PROTOCOL    8   // Interface Device Protocol options
#define SCARD_CLASS_ICC_STATE       9   // ICC State specific definitions
#define SCARD_CLASS_PERF       0x7FFE   // performace counters
#define SCARD_CLASS_SYSTEM     0x7FFF   // System-specific definitions

/* Attribute to set/get whether or not the library automatically handles 
   background execution.
   Valid values are 0 to disable and 1 to enable the feature. The size of the 
   value buffer must be set to sizeof(BYTE). */
#define SCARD_ATTR_AUTO_BACKGROUND_HANDLING SCARD_ATTR_VALUE(SCARD_CLASS_VENDOR_DEFINED, 0xB100) 

typedef LONG SCARDCONTEXT; 
typedef SCARDCONTEXT *PSCARDCONTEXT;
typedef SCARDCONTEXT *LPSCARDCONTEXT;
typedef LONG SCARDHANDLE; 
typedef SCARDHANDLE *PSCARDHANDLE;
typedef SCARDHANDLE *LPSCARDHANDLE;

/** An invalid scard handle. */
#define SCARD_HANDLE_INVALID    0

#ifdef __APPLE__
#pragma pack(1)
#endif

/** Used by functions for tracking smart cards within readers. */
typedef struct
{
    /** A pointer to the name of the reader being monitored.*/
    const char *szReader;
    /** Not used by the smart card subsystem. This member is used by the 
    application*/
    void *pvUserData;
    /** Current state of the reader, as seen by the application. This field can 
    take on any of the \ref g_reader_state, in combination, as a 
    bitmask. */
    DWORD dwCurrentState;
    /** Current state of the reader, as known by the smart card resource 
    manager. This field can take on any of the \ref g_reader_state, in 
    combination, as a bitmask. 
    */
    DWORD dwEventState;
    /** Number of bytes in the returned ATR.*/
    DWORD cbAtr;
    /** ATR of the inserted card.*/
    unsigned char rgbAtr[33]; 
}
SCARD_READERSTATE, *LPSCARD_READERSTATE;

/** Protocol Control Information (PCI) */
typedef struct
{
    /** Protocol identifier */
    unsigned long dwProtocol;	
    /** Protocol Control Inf Length */
    unsigned long cbPciLength;	
}
SCARD_IO_REQUEST, *PSCARD_IO_REQUEST, *LPSCARD_IO_REQUEST;

#ifdef __APPLE__
#pragma pack()
#endif

typedef const SCARD_IO_REQUEST *LPCSCARD_IO_REQUEST;
extern SCARD_IO_REQUEST g_rgSCardT0Pci, g_rgSCardT1Pci, g_rgSCardRawPci;

/** @defgroup g_pci PCI structures  
@{*/
/** protocol control information (PCI) for T=0 */    
#define SCARD_PCI_T0                (&g_rgSCardT0Pci) 
/** protocol control information (PCI) for T=1 */
#define SCARD_PCI_T1                (&g_rgSCardT1Pci) 
/** protocol control information (PCI) for RAW protocol */
#define SCARD_PCI_RAW               (&g_rgSCardRawPci) 
/*@}*/

/** @defgroup g_c_api PCSC winscard.h smart card API
@{*/
/**
	Initializes the ExternalAccessory framework enabling communications with 
	the Precise Biometrics iOS smart card reader. 
	@param[in] dwScope Scope of the resource manager context. Only 
	SCARD_SCOPE_USER and SCARD_SCOPE_SYSTEM are valid values. 
	@param[in] pvReserved1 Reserved for future use and must be NULL.
	@param[in] pvReserved2 Reserved for future use and must be NULL.
	@param[out] phContext A handle to the established resource manager context. 
	This handle can now be supplied to other functions attempting to do work 
	within this context.
	@returns SCARD_S_SUCCESS if successful. Otherwise an error code is 
	returned. See \ref g_error for valid return values
 */
LONG SCardEstablishContext(DWORD dwScope,
                           LPCVOID pvReserved1,
                           LPCVOID pvReserved2,
                           LPSCARDCONTEXT phContext);

/**
	Releases the session to the accessory and the ExternalAccessory framework
	when the last context is released. 
	Any smart card present in the reader will be powered off automatically. 
	@param[in] hContext Context parameter received from a previous call to 
	SCardEstablishContext().
	@returns SCARD_S_SUCCESS if successful. Otherwise an error code is 
	returned. See \ref g_error for valid return values
 */
LONG SCardReleaseContext(SCARDCONTEXT hContext);

/**
	Establishes a connection between the calling application and a smart card 
	contained by a specific reader. If no card exists in the specified reader, 
	an error is returned.
	@param[in] hContext Context parameter received from a previous call to 
	SCardEstablishContext().
	@param[in] szReader The name of the reader that contains the target card
	@param[in] dwShareMode A flag that indicates whether other applications may 
	form connections to the card. At the moment only SCARD_SHARE_EXCLUSIVE() is 
	a valid value. 
	@param[in] dwPreferredProtocols A bitmask of acceptable protocols for the 
	connection. See \ref g_protocol for valid values. 
	@param[out] phCard A handle that identifies the connection to the smart card
	in the designated reader.
	@param[out] pdwActiveProtocol Flag that indicates the established active 
	protocol. See \ref g_protocol for valid values. 
	@returns SCARD_S_SUCCESS if successful. Otherwise an error code is 
	returned. See \ref g_error for valid return values
 */
LONG SCardConnect(SCARDCONTEXT hContext,
                  LPCSTR szReader,
                  DWORD dwShareMode,
                  DWORD dwPreferredProtocols,
                  LPSCARDHANDLE phCard,
                  LPDWORD pdwActiveProtocol);

/**
	reestablishes an existing connection between the calling application and a 
	smart card. This function moves a card handle from direct access to general 
	access, or acknowledges and clears an error condition that is preventing 
	further access to the card.
	@param[in] hCard Reference value obtained from a previous call to 
	SCardConnect().
	@param[in] dwShareMode A flag that indicates whether other applications may 
	form connections to the card. At the moment only SCARD_SHARE_EXCLUSIVE is 
	a valid value. 
	@param[in] dwPreferredProtocols A bitmask of acceptable protocols for the 
	connection. See \ref g_protocol for valid values. 
	@param[in] dwInitialization Type of initialization that should be performed on
	the card. See \ref g_disposition for valid values. 
	@param[out] pdwActiveProtocol Flag that indicates the established active 
	protocol. See \ref g_protocol for valid values. 
	@returns SCARD_S_SUCCESS if successful. Otherwise an error code is 
	returned. See \ref g_error for valid return values
 */
LONG SCardReconnect(SCARDHANDLE hCard,
                    DWORD dwShareMode,
                    DWORD dwPreferredProtocols,
                    DWORD dwInitialization,
                    LPDWORD pdwActiveProtocol);

/**
	Terminates a connection previously opened between the calling application 
	and a smart card in the target reader.
	@param[in] hCard Reference value obtained from a previous call to 
	SCardConnect().
	@param[in] dwDisposition Action to take on the card in the connected reader 
	on close. See \ref g_disposition for valid values. 
	@returns SCARD_S_SUCCESS if successful. Otherwise an error code is 
	returned. See \ref g_error for valid return values
 */

LONG SCardDisconnect(SCARDHANDLE hCard,
                     DWORD dwDisposition);

/**
	provides the current status of a smart card in a reader. You can call it any
	time after a successful call to SCardConnect() and before a successful call 
	to SCardDisconnect(). It does not affect the state of the reader or reader 
	driver.
	@param[in] hCard Reference value returned from SCardConnect().
	@param[out] mszReaderName List of display names (multiple string) by which 
	the currently connected reader is known.
	@param[in,out] pcchReaderLen On input, supplies the length of the 
	szReaderName buffer. On output, receives the actual length (in characters)
	of the reader name list, including the trailing NULL character. If this 
	buffer length is specified as SCARD_AUTOALLOCATE, then szReaderName is 
	converted to a pointer to a byte pointer, and it receives the address of a 
	block of memory that contains the multiple-string structure.
	@param[out] pdwState Current state of the smart card in the reader. Upon 
	success, it receives one of the following state indicators. See \ref g_card_state
	for valid values. 
	@param[out] pdwProtocol Current protocol, if any. 
	@param[out] pbAtr Pointer to a 32-byte buffer that receives the ATR string 
	from the currently inserted card, if available.
	@param[in,out] pcbAtrLen On input, supplies the length of the pbAtr 
	buffer. On output, receives the number of bytes in the ATR string (32 bytes 
	maximum). If this buffer length is specified as SCARD_AUTOALLOCATE, then 
	pbAtr is converted to a pointer to a byte pointer, and it receives the 
	address of a block of memory that contains the multiple-string structure.
	@returns SCARD_S_SUCCESS if successful. Otherwise an error code is 
	returned. See \ref g_error for valid return values
 */
LONG SCardStatus(SCARDHANDLE hCard,
                 LPSTR mszReaderName,
                 LPDWORD pcchReaderLen,
                 LPDWORD pdwState,
                 LPDWORD pdwProtocol,
                 LPBYTE pbAtr,
                 LPDWORD pcbAtrLen);

/**
	Blocks execution until the current availability of the cards in a specific 
	set of readers changes.
	The caller supplies a list of readers to be monitored by an 
	SCARD_READERSTATE array and the maximum amount of time (in milliseconds) 
	that it is willing to wait for an action to occur on one of the listed 
	readers. Note that SCardGetStatusChange() uses the user-supplied value in 
	the dwCurrentState members of the rgReaderStates SCARD_READERSTATE array
	as the definition of the current state of the readers. The function returns 
	when there is a change in availability, having filled in the dwEventState 
	members of rgReaderStates appropriately.
	@param[in] hContext Context parameter received from a previous call to 
	SCardEstablishContext().
	@param[in] dwTimeout The maximum amount of time, in milliseconds, to wait 
	for an action. A value of zero causes the function to return immediately. A 
	value of INFINITE causes this function never to time out.
	@param rgReaderStates An array of SCARD_READERSTATE structures that specify 
	the readers to watch, and that receives the result.
	@param cReaders The number of elements in the rgReaderStates array.
	@returns SCARD_S_SUCCESS if successful. Otherwise an error code is 
	returned. See \ref g_error for valid return values
 */
LONG SCardGetStatusChange(SCARDCONTEXT hContext,
                          DWORD dwTimeout,
                          LPSCARD_READERSTATE rgReaderStates,
                          DWORD cReaders);
/**
	The SCardTransmit function sends a service request to the smart card and 
	expects to receive data back from the card.
	@param[in] hCard Reference value returned from SCardConnect().
	@param[in] pioSendPci pointer to the protocol header structure for the 
	instruction. This buffer is in the format of an SCARD_IO_REQUEST structure, 
	followed by the specific protocol control information (PCI). For the T=0, 
	T=1, and Raw protocols, the PCI structure is constant. The smart card 
	subsystem supplies a global T=0, T=1, or Raw PCI structure, which you can 
	reference by using the \ref g_pci respectively.
	@param[in] pbSendBuffer A pointer to the actual data to be written to the 
	card. 
	@param[in] cbSendLength The length, in bytes, of the pbSendBuffer parameter. 
	@param[out] pioRecvPci Pointer to the protocol header structure for the 
	instruction, followed by a buffer in which to receive any returned protocol 
	control information (PCI) specific to the protocol in use. This parameter 
	can be NULL if no PCI is returned.
	@param[out] pbRecvBuffer Pointer to any data returned from the card. 
	@param[in,out] pcbRecvLength Supplies the length, in bytes, of the 
	pbRecvBuffer parameter and receives the actual number of bytes received from
	the smart card. This value cannot be SCARD_AUTOALLOCATE because 
	SCardTransmit() does not support SCARD_AUTOALLOCATE.
	@returns SCARD_S_SUCCESS if successful. Otherwise an error code is 
	returned. See \ref g_error for valid return values
 */
LONG SCardTransmit(SCARDHANDLE hCard,
                   const SCARD_IO_REQUEST *pioSendPci,
                   LPCBYTE pbSendBuffer,
                   DWORD cbSendLength,
                   SCARD_IO_REQUEST *pioRecvPci,
                   LPBYTE pbRecvBuffer,
                   LPDWORD pcbRecvLength);

/**
	Provides a list of currently available smart card readers.
	@param[in] hContext Context parameter received from a previous call to 
	SCardEstablishContext().
	@param[in] mszGroups Use a NULL value to list all readers in the system.
	@param[out] mszReaders Multi-string that lists the card readers currently
	connected and available to the system. If this value is NULL, 
	SCardListReaders ignores the buffer length supplied in pcchReaders, writes 
	the length of the buffer that would have been returned if this parameter had
	 not been NULL to pcchReaders, and returns a success code.
	@param[in,out] pcchReaders Length of the mszReaders buffer in characters. 
	This parameter receives the actual length of the multi-string structure, 
	including all trailing null characters. If the buffer length is specified as
	SCARD_AUTOALLOCATE, then mszReaders is converted to a pointer to a byte
	pointer, and receives the address of a block of memory containing the 
	multi-string structure. This block of memory must be deallocated with 
	SCardFreeMemory().
	@returns Returns SCARD_S_SUCCESS if at least one reader is connected and
	available to the system. Returns SCARD_E_NO_READERS_AVAILABLE if no reader
	can be found. Otherwise an error code is 
	returned. See \ref g_error for valid return values
 */
LONG SCardListReaders(SCARDCONTEXT hContext,
                      LPCSTR mszGroups,
                      LPSTR mszReaders,
                      LPDWORD pcchReaders);

/**
	Releases memory that has been returned from the resource manager using the 
	SCARD_AUTOALLOCATE length designator.
	@param[in] hContext Context parameter received from a previous call to 
	SCardEstablishContext().
	@param pvMem Memory block to be released.
	@returns SCARD_S_SUCCESS if successful. Otherwise an error code is 
	returned. See \ref g_error for valid return values
 */
LONG SCardFreeMemory(SCARDCONTEXT hContext,
                     LPCVOID pvMem);

/**
 Cancels an ongoing SCardGetStatusChange() operation. Note that this function
 will cancel operations for all open contexts, not only operations within 
 the hContext parameter context.
 @param[in] hContext Context parameter received from a previous call to 
 SCardEstablishContext().
 @returns SCARD_S_SUCCESS if successful. Otherwise an error code is 
 returned. See \ref g_error for valid return values
 */
LONG SCardCancel(SCARDCONTEXT hContext);

/**
 Determines whether a context handle is valid. 
 @param[in] hContext Context parameter received from a previous call to 
 SCardEstablishContext().
 @returns SCARD_S_SUCCESS if the context is valid. 
 @returns SCARD_E_INVALID_HANDLE if the context is invalid.
 */
LONG SCardIsValidContext(SCARDCONTEXT hContext);

/**
 Sets a reader/context attribute. 
 Supported attributes are:
 SCARD_ATTR_AUTO_BACKGROUND_HANDLING.
 See the doucment "Precise iOS Toolkit User Manual" 
 in the toolkit for further information.  
 The behaviour of the smart card library if this functionality
 is disabled and the application does not handle all relevant iOS events is 
 undefined. This feature is global. Changing the value will affect all open
 contexts and sessions. 
 @param[in] hCard Reference value obtained from a previous call to 
 SCardConnect(). Shall be 0 when used together with 
 SCARD_ATTR_AUTO_BACKGROUND_HANDLING.
 @param[in] dwAttrId Specifies the identifier for the attribute to set.
 @param[in] pbAttr Pointer to a buffer that supplies the attribute whose 
 identifier is supplied in dwAttrId.
 @param[in] cbAttrLen Count of bytes that represent the length of the attribute 
 value in the pbAttr buffer.
 @returns SCARD_S_SUCCESS if successful. Otherwise an error code is 
 returned. See \ref g_error for valid return values
 */
LONG SCardSetAttrib(
    SCARDHANDLE hCard,
    DWORD dwAttrId,
    LPCBYTE pbAttr,
    DWORD cbAttrLen);
    
/**
 Retrieves a reader/context attribute. 
 Supported attributes are:
 SCARD_ATTR_AUTO_BACKGROUND_HANDLING - can be used to the retrieve the current
 state of the automatic background handling.
 @param[in] hCard Reference value obtained from a previous call to 
 SCardConnect(). Ignored in this implementation.
 @param[in] dwAttrId Specifies the identifier for the attribute to get.
 @param[out] pbAttr Pointer to a buffer that receives the attribute whose ID is 
 supplied in dwAttrId. If this value is NULL, SCardGetAttrib ignores the buffer 
 length supplied in pcbAttrLen, writes the length of the buffer that would have 
 been returned if this parameter had not been NULL to pcbAttrLen, and returns a 
 success code.
 @param[in,out] pcbAttrLen Length of the pbAttr buffer in bytes, and receives the 
 actual length of the received attribute If the buffer length is specified as 
 SCARD_AUTOALLOCATE, then pbAttr is converted to a pointer to a byte pointer, 
 and receives the address of a block of memory containing the attribute. This 
 block of memory must be deallocated with SCardFreeMemory.
 @returns SCARD_S_SUCCESS if successful. Otherwise an error code is 
 returned. See \ref g_error for valid return values
 */
LONG SCardGetAttrib(
    SCARDHANDLE hCard,
    DWORD dwAttrId,
    LPBYTE pbAttr,
    LPDWORD pcbAttrLen);


#pragma mark Currently not implemented 

/**
	This function is not implemented for iOS. 
	@returns Always returns ENOSYS 
 */
LONG SCardListReaderGroups(SCARDCONTEXT hContext,
                           LPSTR mszGroups,
                           LPDWORD pcchGroups);

/**
	This function is not implemented for iOS. 
	@returns Always returns ENOSYS 
 */
LONG SCardControl(SCARDHANDLE hCard,
                  DWORD dwControlCode,
                  LPCVOID pbSendBuffer,
                  DWORD cbSendLength,
                  LPVOID pbRecvBuffer,
                  DWORD cbRecvLength,
                  LPDWORD lpBytesReturned);
/**
	This function is not implemented for iOS. 
	@returns Always returns ENOSYS 
 */
LONG SCardBeginTransaction(SCARDHANDLE hCard);
/**
	This function is not implemented for iOS. 
	@returns Always returns ENOSYS 
 */
LONG SCardEndTransaction(SCARDHANDLE hCard,
                         DWORD dwDisposition);
/*@}*/                         

#endif /* _WINSCARD_H_ */


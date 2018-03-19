/**
 * @file
 * @This isfeitian's private cmd.
 */

#ifndef __ft301u_h__
#define __ft301u_h__


#include "wintypes.h"

typedef enum READERTYPE{
    READER_UNKOWN = 0,
    READER_bR301,
    READER_iR301U_DOCK,
    READER_iR301U_LIGHTING
    
}READERTYPE;

#ifdef __cplusplus
extern "C"
{
#endif
    
    
    LONG SCARD_CTL_CODE(unsigned int code);
    /*
    Function: FtGetSerialNum
 
    Parameters:
    hCard 			IN 		Connection made from SCardConnect(Ignore this parameter and just set to zero in iOS system)
    length			IN		length of buffer(>=8)
    buffer       	OUT		Serial number
 
    Description:
    This function userd to get serial number of iR301.
    */
    
    LONG FtGetSerialNum(SCARDHANDLE hCard, unsigned int  length,
                                      char * buffer);
    /*
     Function: FtWriteFlash   
  
     Parameters:
     hCard          IN 		Connection made from SCardConnect(Ignore this parameter and just set to zero in iOS system)
     bOffset		IN		Offset of flash to write
     blength		IN		The length of data
     buffer       	IN		The data for write
  
     Description:
     This function userd to write data to flash.
     */
    LONG FtWriteFlash(SCARDHANDLE hCard,unsigned char bOffset, unsigned char blength,
                      unsigned char buffer[]);
    /*
     Function: FtReadFlash
 
     Parameters:
     hCard 			IN 		Connection made from SCardConnect(Ignore this parameter and just set to zero in iOS system)
     bOffset		IN		Offset of flash to write
     blength		IN		The length of read data
     buffer       	OUT		The read data
 
     Description:
     This function used to read data from flash.
     */
    LONG FtReadFlash(SCARDHANDLE hCard,unsigned char bOffset, unsigned char blength,
                     unsigned char buffer[]);
    
    /*
     Function: FtSetTimeout
 
     Parameters:
        hContext	IN	 Connection context to the PC/SC Resource Manager
        dwTimeout 	IN	 New transmission timeout value of between 301 and card (millisecond )
     
     Description:
     The function New transmission timeout value of between 301 and card.
 
     */
    LONG FtSetTimeout(SCARDCONTEXT hContext, DWORD dwTimeout);
    
    /*
     Function: FT_AutoTurnOffReader
     
     Parameters:
     isOpen 	  IN  the switch is able to open/close the  automatic shutdown function of reader.
     
     Description:
     The function is able to open/close the  automatic shutdown function  of reader.
     
     */
    LONG FT_AutoTurnOffReader(BOOL isOpen);
    //for dukpt
    /*
     Function: FtDukptInit
     
     Parameters:
     hCard 		IN 	 Connection made from SCardConnect(Ignore this parameter and just set to zero in iOS system)
     encBuf 	IN	 Ciphertext use TDES_ECB_PKCS7/AES_ECB_PKCS7 (See "Key C" )
     nLen       IN	 encBuf length(40(TDES_ECB_PKCS7 ciphertext length) 48(AES_ECB_PKCS7 ciphertext length))
     
     Description:
     Init iR301 new ipek and ksn for dukpt.
     
     */
    LONG FtDukptInit(SCARDHANDLE hCard,unsigned char *encBuf,unsigned int nLen);
    
    
    /*
     Function: FtDukptSetEncMod
     
     Parameters:
     hCard 		IN 	 Connection made from SCardConnect(Ignore this parameter and just set to zero in iOS system)
     bEncrypt 	IN	 1: SCardTransmit  Encrypted    
                     0:SCardTransmit not Encrypted
     
     bEncFunc	IN	 0: Encryption functioon use TDES_ECB_PKCS7
                     1:Encryption functioon use AES_ECB_PKCS7
     
     bEncType	IN	 1: SCardTransmit: Plaintext in Ciphertext out 
                     0: SCardTransmit: Ciphertext in Ciphertext out 
     
     Description:
     Set the encryption mode of iR301 for dukpt.
     
     */
    LONG FtDukptSetEncMod(SCARDHANDLE hCard,
                          unsigned int bEncrypt,
                          unsigned int bEncFunc,
                          unsigned int bEncType);
    
    
    
    
    /*
     Function: FtDukptGetKSN
     
     Parameters:
     hCard 		IN      Connection made from SCardConnect(Ignore this parameter and just set to zero in iOS system)
     pnlength 	INOUT	IN: The size of ksn buffer(>=10) 
                        OUT: The real size(if successful has been 10)
     buffer 	OUT     Buffer of ksn
     
     Description:
     Get Ksn from iR301 for dukpt.
     
     */
    
    LONG FtDukptGetKSN(SCARDHANDLE hCard,unsigned int * pnlength,unsigned char *buffer);
    /*
     Function: FtDidEnterBackground
     
     Parameters:
     bDidEnter 	IN	 must be set 1
                     
     
     Description:
     Use this method to release monitor thread of reader status
     
     */
    void FtDidEnterBackground(unsigned int bDidEnter);
   
    /*
     Function: FtGetDevVer
     
     Parameters:
     hContext           IN      Connection made from SCardConnect(Ignore this parameter and just set to zero in iOS system)
     firmwareRevision 	INOUT	IN: The buffer  OUT: The real buffer contain return version data
     hardwareRevision 	INOUT   IN: The buffer  OUT: The real buffer contain return version data
     
     Description:
     Get the current Reader firm Version and hardware Version
     
     */
    LONG FtGetDevVer( SCARDCONTEXT hContext,char *firmwareRevision,char *hardwareRevision);
    
    
    /*
     Function: FtGetLibVersion
     
     Parameters:
     buffer :    INOUT	IN: The buffer  OUT: The real buffer contain lib version data
     
     
     Description:
     Get the Current Lib Version
     
     */
    
    void FtGetLibVersion (char *buffer);
    
    /*
     Function: FtGetCurrentReaderType
     
     Parameters:
     readerType :   INOUT	IN: int value  OUT: The real current reader type
     
     
     Description:
     Get current Reader Type
     
     */
    
    LONG FtGetCurrentReaderType(unsigned int *readerType);
    
#ifdef __cplusplus
}
#endif

#endif


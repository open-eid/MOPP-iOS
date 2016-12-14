//
//  CardLib.m
//  iEstEidUtil
//
//  Created by Raul Metsma on 21.05.12.
//  Copyright (c) 2012 SK. All rights reserved.
//

#import "CardLib.h"

extern "C" {
#import "winscard.h"
}

#import <string>

class EstEid
{
public:
	enum PinType
	{
		PukType = 0,
		Pin1Type = 1,
		Pin2Type = 2
	};

	EstEid( SCARDHANDLE card );

	bool changePin( PinType type, const std::string &oldpin, const std::string &newpin );
	void read();

	std::string presonalfile[16];
	std::string certs[2];
	DWORD tries[3];
	DWORD count[4];

private:
	std::string sendCommand( LPCBYTE cmd, DWORD cmdsize ) const;
	std::string readBinary() const;

	SCARDHANDLE card;
	mutable DWORD sw1, sw2;

	struct CmdBytes {
		BYTE
			bCla,   // the instruction class
			bIns,   // the instruction code
			bP1,    // parameter to the instruction
			bP2,    // parameter to the instruction
			bP3;    // size of I/O transfer
	};
	struct SelectFile { CmdBytes header; BYTE data[2]; };

	static const CmdBytes SELECT_MASTER_FILE;
	static const CmdBytes SELECT_FILE;
	static const SelectFile TRIES_LEFT;
	static const SelectFile COUNTERS;
	static const SelectFile SELECT_ESTEIDDF;
	static const SelectFile SELECT_PERSONALDATA;
	static const SelectFile SELECT_AUTHCERT;
	static const SelectFile SELECT_SIGNCERT;
};

const EstEid::CmdBytes EstEid::SELECT_MASTER_FILE = { 0x00, 0xA4, 0x00, 0x0C, 0x00 };
const EstEid::CmdBytes EstEid::SELECT_FILE = { 0x00, 0xA4, 0x02, 0x04, 0x02 };

const EstEid::SelectFile EstEid::TRIES_LEFT = { { 0x00, 0xA4, 0x02, 0x0C, 0x02 }, { 0x00, 0x16 } };
const EstEid::SelectFile EstEid::COUNTERS = { { 0x00, 0xA4, 0x02, 0x0C, 0x02 }, { 0x00, 0x13 } };

const EstEid::SelectFile EstEid::SELECT_ESTEIDDF = { { 0x00, 0xA4, 0x01, 0x0C, 0x02 }, { 0xEE, 0xEE } };
const EstEid::SelectFile EstEid::SELECT_PERSONALDATA = { SELECT_FILE, { 0x50, 0x44 } };
const EstEid::SelectFile EstEid::SELECT_AUTHCERT = { SELECT_FILE, { 0xAA, 0xCE } };
const EstEid::SelectFile EstEid::SELECT_SIGNCERT = { SELECT_FILE, { 0xDD, 0xCE } };

EstEid::EstEid( SCARDHANDLE _card ): card(_card), sw1(0), sw2(0) {}

void EstEid::read()
{
	sendCommand( (LPBYTE)&SELECT_MASTER_FILE, sizeof(SELECT_MASTER_FILE) );
	if( sw1 == 0x90 && sw2 == 0x00 )
		return;

	sendCommand( (LPBYTE)&TRIES_LEFT, sizeof(COUNTERS) );
	for( unsigned int i = 1; i <= 3; ++i )
	{
		CmdBytes cmd = { 0x00, 0xB2, i, 0x04, 0x00 };
		std::string data = sendCommand( (LPBYTE)&cmd, sizeof(cmd) );
		if( sw1 == 0x90 && sw2 == 0x00 )
			tries[i - 1] = data[5];
	}

	sendCommand( (LPBYTE)&SELECT_ESTEIDDF, sizeof(SELECT_ESTEIDDF) );
	if( sw1 == 0x90 && sw2 == 0x00 )
		return;

	sendCommand( (LPBYTE)&COUNTERS, sizeof(COUNTERS) );
	for( unsigned int i = 1; i <= 4; ++i )
	{
		CmdBytes cmd = { 0x00, 0xB2, i, 0x04, 0x00 };
		std::string data = sendCommand( (LPBYTE)&cmd, sizeof(cmd) );
		if( sw1 == 0x90 && sw2 == 0x00 )
			count[i-1] = 0xFFFFFF - ((BYTE(data[12]) << 16) + (BYTE(data[13]) << 8) + BYTE(data[14]));
	}

	sendCommand( (LPBYTE)&SELECT_PERSONALDATA, sizeof(SELECT_PERSONALDATA) );
	for( unsigned int i = 1; i <= 16; ++i )
	{
		CmdBytes cmd = { 0x00, 0xB2, i, 0x04, 0x00 };
		presonalfile[i - 1] = sendCommand( (LPBYTE)&cmd, sizeof(cmd) );
	}

	sendCommand( (LPBYTE)&SELECT_AUTHCERT, sizeof(SELECT_AUTHCERT) );
	certs[0] = readBinary();
	if( sw1 == 0x90 && sw2 == 0x00 )
		certs[0].resize( BYTE(certs[0][2]) * 256 + BYTE(certs[0][3]) + 4 );

	sendCommand( (LPBYTE)&SELECT_SIGNCERT, sizeof(SELECT_SIGNCERT) );
	certs[1] = readBinary();
	if( sw1 == 0x90 && sw2 == 0x00 )
		certs[1].resize( BYTE(certs[1][2]) * 256 + BYTE(certs[1][3]) + 4 );
}

bool EstEid::changePin( PinType type, const std::string &oldpin, const std::string &newpin )
{
	LPBYTE cmd = new BYTE[5+oldpin.size()+newpin.size()];
	cmd[0] = 0x00;
	cmd[1] = 0x24;
	cmd[2] = 0x00;
	cmd[3] = type;
	cmd[4] = oldpin.size() + newpin.size();
	memcpy( &cmd[5], oldpin.c_str(), oldpin.size() );
	memcpy( &cmd[5+oldpin.size()], newpin.c_str(), newpin.size() );
	sendCommand( cmd, 5 + oldpin.size() + newpin.size() );
	return sw1 == 0x90 && sw2 == 0x00;
}

std::string EstEid::readBinary() const
{
	std::string result;
	while( result.size() < 0x0600 )
	{
		CmdBytes cmd = { 0x00, 0xB0, BYTE(result.size() >> 8), BYTE(result.size()), 0x00 };
		result += sendCommand( (LPBYTE)&cmd, sizeof(cmd) );
		if( sw1 == 0x90 && sw2 == 0x00 )
			return std::string();
	}
	return result;
}

std::string EstEid::sendCommand( LPCBYTE cmd, DWORD cmdsize ) const
{
	sw1 = sw2 = 0;
	static const SCARD_IO_REQUEST PCI_T0 = { 1, 8 };
	BYTE data[255 + 3];
	DWORD size = sizeof(data);

	DWORD ret = SCardTransmit( card, &PCI_T0, cmd, cmdsize, NULL, (LPBYTE)&data, &size );
	if( ret != SCARD_S_SUCCESS )
		return std::string();

	if( data[0] == 0x61 )
	{
		size = sizeof(data);
		CmdBytes additional = { 0x00, 0xC0, 0x00, 0x00, data[1] };
		ret = SCardTransmit( card, &PCI_T0, (LPCBYTE)&additional, sizeof(additional), NULL, (LPBYTE)&data, &size );
	}

	if( size > 2 )
		return std::string( (char*)data, size - 2 );
	sw1 = data[size-2];
	sw2 = data[size-1];
	return std::string();
}



@interface NSString (CardLib)
+ (NSString*)stdstring:(const std::string&)str;
@end

@implementation NSString (CardLib)
+ (NSString*)stdstring:(const std::string&)str
{
    return str.empty() ? [NSString string] : [NSString stringWithCString:str.c_str() encoding:NSWindowsCP1252StringEncoding];
}
@end


@interface CardLib () {
    SCARDCONTEXT context;
    LPSTR reader;
    SCARDHANDLE card;
    DWORD proto;
}

@end

@implementation CardLib

@synthesize delegate;
@synthesize atr, personalfile, authCert, signCert, authLeft, authUsage, signLeft, signUsage;

- (id)init
{
    if (self = [super init]) {
        context = 0;
        reader = 0;
        [[PBAccessory sharedClass] addDelegate:self];
        [self pbAccessoryDidConnect];
    }
    return self;
}

- (id)initWithDelegate:(id<CardLibDelegate>) _delegate
{
    if (self = [super init]) {
        context = 0;
        reader = 0;
        delegate = _delegate;
        [[PBAccessory sharedClass] addDelegate:self];
        [self pbAccessoryDidConnect];
    }
    return self;
}

- (void)pbAccessoryDidConnect
{
    DWORD ret = SCardEstablishContext(SCARD_SCOPE_SYSTEM, NULL, NULL, &context);
    switch (ret) {
        case SCARD_E_NO_READERS_AVAILABLE:
            [delegate message:[NSString stringWithFormat:@"No readers"]];
            break;
        case SCARD_S_SUCCESS:
        {
            DWORD size = SCARD_AUTOALLOCATE;
            ret = SCardListReaders(context, NULL, (LPSTR)&reader, &size);
            if (ret != SCARD_S_SUCCESS) {
                [delegate message:[NSString stringWithFormat:@"SCardListReaders failed: %u", ret]];
                break;
            }
            //[delegate message:[NSString stringWithFormat:@"Reader '%s' present", reader]];
            [self connect];
            break;
        }
        default:
            [delegate message:[NSString stringWithFormat:@"SCardEstablishContext failed: %u", ret]];
            break;
    }
}

- (void)pbAccessoryDidDisconnect
{
    SCardFreeMemory(context, reader);
    //SCardReleaseContext(context);
    reader = 0;
    [delegate message:[NSString stringWithFormat:@"No readers"]];
}

- (bool)changePin1:(NSString *)oldpin newpin:(NSString *)pin
{
    EstEid esteid( card );
    return esteid.changePin(EstEid::Pin1Type, [oldpin UTF8String], [pin UTF8String]);
}

- (bool)changePin2:(NSString *)oldpin newpin:(NSString *)pin
{
    EstEid esteid( card );
    return esteid.changePin(EstEid::Pin2Type, [oldpin UTF8String], [pin UTF8String]);
}

- (bool)changePuk:(NSString *)oldpin newpin:(NSString *)pin
{
    EstEid esteid( card );
    return esteid.changePin(EstEid::PukType, [oldpin UTF8String], [pin UTF8String]);
}

- (void)connect
{
    DWORD ret = SCardConnect(context, reader, SCARD_SHARE_EXCLUSIVE, SCARD_PROTOCOL_T0, &card, &proto);
    if (ret != SCARD_S_SUCCESS) {
        [delegate message:[NSString stringWithFormat:@"SCardConnect failed: %u", ret]];
        return;
    }

    BYTE atrdata[256];
    DWORD size = sizeof(atrdata);
    ret = SCardStatus(card, 0, 0, 0, 0, (LPBYTE)&atrdata, &size);
    if (ret != SCARD_S_SUCCESS) {
        [delegate message:[NSString stringWithFormat:@"SCardStatus failed: %u", ret]];
        return;
    }
    atr = [NSString stdstring: std::string((char*)&atrdata, size)];

    EstEid esteid( card );
    esteid.read();
    NSMutableArray *data = [NSMutableArray array];
    for (int i = 0; i < 16; ++i) {
        [data addObject:[NSString stdstring:esteid.presonalfile[i]]];
    }
    personalfile = data;
    authCert = [NSData dataWithBytes:esteid.certs[0].c_str() length:esteid.certs[0].size()];
    signCert = [NSData dataWithBytes:esteid.certs[1].c_str() length:esteid.certs[1].size()];
    authLeft = esteid.tries[0];
    signLeft = esteid.tries[1];
    authUsage = esteid.count[2] ? esteid.count[2] : esteid.count[0];
    signUsage = esteid.count[3] ? esteid.count[3] : esteid.count[1];
    [delegate message:@"Data loaded"];
}

@end

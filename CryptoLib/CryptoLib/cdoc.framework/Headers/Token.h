#pragma once

#include "CDOCExport.h"

#include <string>
#include <vector>

typedef unsigned char uchar;
#define DISABLE_COPY(Class) \
	Class(const Class &) = delete; \
	Class &operator=(const Class &) = delete

class CDOC_EXPORT Token
{
public:
	virtual ~Token();
	virtual std::vector<uchar> cert() const = 0;
	virtual std::vector<uchar> decrypt(const std::vector<uchar> &data) const = 0;
	virtual std::vector<uchar> derive(const std::vector<uchar> &publicKey) const;
	virtual std::vector<uchar> deriveConcatKDF(const std::vector<uchar> &publicKey, const std::string &digest, unsigned int keySize,
		const std::vector<uchar> &algorithmID, const std::vector<uchar> &partyUInfo, const std::vector<uchar> &partyVInfo) const;
protected:
	Token();
private:
	DISABLE_COPY(Token);
};

class CDOC_EXPORT PKCS11Token: public Token
{
public:
	PKCS11Token(const std::string &path, const std::string &password);
	~PKCS11Token();
	virtual std::vector<uchar> cert() const override;
	std::vector<uchar> decrypt(const std::vector<uchar> &data) const override;
	std::vector<uchar> derive(const std::vector<uchar> &publicKey) const override;
private:
	DISABLE_COPY(PKCS11Token);
	class Private;
	Private *d;
};

class CDOC_EXPORT PKCS12Token: public Token
{
public:
	PKCS12Token(const std::string &path, const std::string &password);
	~PKCS12Token();
	virtual std::vector<uchar> cert() const override;
	std::vector<uchar> decrypt(const std::vector<uchar> &data) const override;
	std::vector<uchar> derive(const std::vector<uchar> &publicKey) const override;
private:
	DISABLE_COPY(PKCS12Token);
	class Private;
	Private *d;
};

#ifdef _WIN32
class CDOC_EXPORT WinToken: public Token
{
public:
	WinToken(bool ui, const std::string &pass);
	~WinToken();
	virtual std::vector<uchar> cert() const override;
	std::vector<uchar> decrypt(const std::vector<uchar> &data) const override;
	std::vector<uchar> deriveConcatKDF(const std::vector<uchar> &publicKey, const std::string &digest, unsigned int keySize,
		const std::vector<uchar> &algorithmID, const std::vector<uchar> &partyUInfo, const std::vector<uchar> &partyVInfo) const override;
private:
	DISABLE_COPY(WinToken);
	class Private;
	Private *d;
};
#endif

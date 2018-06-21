#pragma once

#include "CDOCExport.h"

#include <string>
#include <vector>

class Token;
class CDOC_EXPORT CDOCReader
{
public:
	CDOCReader(const std::string &file);
	~CDOCReader();

	std::string mimeType() const;
	std::string fileName() const;
	std::vector<unsigned char> decryptData(const std::vector<unsigned char> &key);
	std::vector<unsigned char> decryptData(Token *token);

private:
	CDOCReader(const CDOCReader &) = delete;
	CDOCReader &operator=(const CDOCReader &) = delete;
	class Private;
	Private *d;
};

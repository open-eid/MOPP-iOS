#pragma once

#include "CDOCExport.h"

#include <string>
#include <vector>

class CDOC_EXPORT CDOCWriter
{
public:
	CDOCWriter(const std::string &file, const std::string &method = "http://www.w3.org/2009/xmlenc11#aes256-gcm");
	~CDOCWriter();

	void addFile(const std::string &filename, const std::string &mime, const std::vector<unsigned char> &data);
	void addFile(const std::string &filename, const std::string &mime, const std::string &path);
	void addRecipient(const std::vector<unsigned char> &recipient);
	bool encrypt();
	std::string lastError() const;

private:
	CDOCWriter(const CDOCWriter &) = delete;
	CDOCWriter &operator=(const CDOCWriter &) = delete;
	class Private;
	Private *d;
};

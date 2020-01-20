# MOPP-iOS

![EU Regional Development Fund](EL_Regionaalarengu_Fond_horisontaalne-vaike.jpg)

* License: LGPL 2.1
* &copy; Estonian Information System Authority

This repo contains source code for RIA DigiDoc application for iOS.
This application contains following functionality:
* Sign documents with ID card or Mobile-ID
* Encrypt and decrypt documents
* Control ID-card certificates validity
* Change or unlock PIN/PUK codes

## libdigidocpp
MOPP-iOS is using unofficial static version of libdigidoc. libdigidoc is used in app for managing container manipulations. More info: https://github.com/open-eid/libdigidocpp


## Building source code with Xcode
Installation instructions are available in Wiki: 
[Building source code with Xcode](https://github.com/open-eid/MOPP-iOS/wiki/Building-source-code-with-Xcode)

## Signing documents in third-party application
In [releases](https://github.com/open-eid/MOPP-iOS/releases) you will find framework, that you can use in your own application to implement document signing feature. For more detailed instructions check out [wiki page](https://github.com/open-eid/MOPP-iOS/wiki).

## Support
Official builds are provided through official distribution point [installer.id.ee](https://installer.id.ee). If you want support, you need to be using official builds. Contact our support via www.id.ee for assistance.

Source code is provided on "as is" terms with no warranty (see license for more information). Do not file Github issues with generic support requests.

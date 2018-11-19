# MOPP-iOS

![EU Regional Development Fund](EL_Regionaalarengu_Fond_horisontaalne-vaike.jpg)

* License: LGPL 2.1
* &copy; Estonian Information System Authority

This repo contains source code for RIA DigiDoc application for iOS. This application enables user to sign documents with ID card or Mobile-ID. It can also be used to encrypt and decrypt documents.

## libdigidocpp
MOPP-iOS is using unofficial static version of libdigidoc. libdigidoc is used in app for managing container manipulations. More info: https://github.com/open-eid/libdigidocpp


## Building source code with Xcode
This project uses cocoapods for dependencies management. If you don't have cocoapods installed in your machine, or are using older version of cocoapods, you can install it in terminal by running command "sudo gem install cocoapods". For more information go to https://cocoapods.org/

Once you have cocoapods installed, you need to install podfiles, that this project requires.
 1. In terminal navigate to MoppApp folder in project.
 2. Run command "pod install".

In the future, when you pull updates from repo, you may need to repeat "pod install". This is necessary when there are changes to pod dependencies. When only pod version has changed, you may use "pod update" instead.

Make sure you open project with MoppApp.xcworkspace after installing pod files. Use MoppApp target for building.

## Signing documents in third-party application
In [releases](https://github.com/open-eid/MOPP-iOS/releases) you will find framework, that you can use in your own application to implement document signing feature. For more detailed instructions check out [wiki page](https://github.com/open-eid/MOPP-iOS/wiki).

## Support
Official builds are provided through official distribution point [installer.id.ee](https://installer.id.ee). If you want support, you need to be using official builds. Contact for assistance by email [abi@id.ee](mailto:abi@id.ee) or [www.id.ee](http://www.id.ee).

Source code is provided on "as is" terms with no warranty (see license for more information). Do not file Github issues with generic support requests.

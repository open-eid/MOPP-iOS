#!/bin/sh

if [ ! -d cdoc ]; then
    git clone -b mopp https://github.com/metsma/cdoc.git;
fi
export PATH=$PATH:/usr/local/bin:/opt/homebrew/bin
BUILD_DIR=${TARGET_BUILD_DIR}/cdoc
cmake \
    -DINSTALL_FRAMEWORKDIR=${BUILT_PRODUCTS_DIR} \
    -DCMAKE_INSTALL_PREFIX=${BUILT_PRODUCTS_DIR} \
    -DCMAKE_BUILD_TYPE=${CONFIGURATION} \
    -DCMAKE_OSX_SYSROOT=${PLATFORM_NAME} \
    -DCMAKE_OSX_ARCHITECTURES="${ARCHS// /;}" \
    -DBUILD_SHARED_LIBS=YES \
    -DOPENSSL_ROOT_DIR=${PROJECT_DIR}/../MoppLib/MoppLib/libdigidocpp/libdigidocpp.${PLATFORM_NAME} \
    -DSWIG_DIR=NOTFOUND \
    -DDOXYGEN_EXECUTABLE=NOTFOUND \
    -S cdoc -B ${BUILD_DIR}
cmake --build ${BUILD_DIR}
cmake --install ${BUILD_DIR}

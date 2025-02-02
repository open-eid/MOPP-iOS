: ${OPENLDAP:=openldap-2.6.9}
: ${IPHONEOS_DEPLOYMENT_TARGET:="13.0"}
: ${ARCHS:="arm64"}
: ${PREFIX=${BUILT_PRODUCTS_DIR}/openldap}
: ${PLATFORM_NAME:="iphoneos"}
SYSROOT=$(xcrun -sdk ${PLATFORM_NAME} --show-sdk-path)
OPENSSL_DIR=${PROJECT_DIR}/../MoppLib/MoppLib/libdigidocpp/libdigidocpp.${PLATFORM_NAME}
SOURCE_DIR=${DERIVED_SOURCES_DIR}
export IPHONEOS_DEPLOYMENT_TARGET
export CFLAGS="-arch ${ARCHS// / -arch } -isysroot ${SYSROOT}"
export CXXFLAGS="${CFLAGS}"
export CPPFLAGS="${CFLAGS} -I${OPENSSL_DIR}/include"
export LDFLAGS="-L${OPENSSL_DIR}/lib"

mkdir -p ${SOURCE_DIR}
cd ${SOURCE_DIR}
if [ ! -f ${OPENLDAP}.tgz ]; then
  curl -O -L http://mirror.eu.oneandone.net/software/openldap/openldap-release/${OPENLDAP}.tgz
fi
if [ ! -d ${OPENLDAP} ]; then
    tar xf ${OPENLDAP}.tgz
    cd ${OPENLDAP}
    sed -ie 's! clients servers tests doc!!' Makefile.in
    cd ${TARGET_TEMP_DIR}
    echo ${SOURCE_DIR}/${OPENLDAP}/configure
    ${SOURCE_DIR}/${OPENLDAP}/configure --host=arm-apple-darwin \
       --prefix=${PREFIX} --enable-static --disable-shared --disable-syslog --disable-local \
       --disable-slapd --disable-cleartext --disable-mdb --disable-relay --disable-syncprov \
       --without-cyrus-sasl --without-systemd --without-fetch --without-threads --with-tls=openssl --without-argon2 \
       ac_cv_func_memcmp_working=yes lt_cv_apple_cc_single_mod=yes || cat config.log
else
    cd ${TARGET_TEMP_DIR}
fi
make install
cp ${PROJECT_DIR}/openldap.modulemap ${PREFIX}/include/module.modulemap

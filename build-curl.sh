#!/bin/bash
set -e

# Setup ohos-sdk
curl -L -O https://repo.huaweicloud.com/openharmony/os/6.0-Release/ohos-sdk-windows_linux-public.tar.gz
mkdir /opt/ohos-sdk
tar -zxf ohos-sdk-windows_linux-public.tar.gz -C /opt/ohos-sdk
cd /opt/ohos-sdk/linux
unzip -q native-*.zip
cd - >/dev/null

# Setup env
export OHOS_SDK=/opt/ohos-sdk/linux
export AS=${OHOS_SDK}/native/llvm/bin/llvm-as
export CC="${OHOS_SDK}/native/llvm/bin/clang --target=aarch64-linux-ohos"
export CXX="${OHOS_SDK}/native/llvm/bin/clang++ --target=aarch64-linux-ohos"
export LD=${OHOS_SDK}/native/llvm/bin/ld.lld
export STRIP=${OHOS_SDK}/native/llvm/bin/llvm-strip
export RANLIB=${OHOS_SDK}/native/llvm/bin/llvm-ranlib
export OBJDUMP=${OHOS_SDK}/native/llvm/bin/llvm-objdump
export OBJCOPY=${OHOS_SDK}/native/llvm/bin/llvm-objcopy
export NM=${OHOS_SDK}/native/llvm/bin/llvm-nm
export AR=${OHOS_SDK}/native/llvm/bin/llvm-ar
export CFLAGS="-fPIC -D__MUSL__=1"
export CXXFLAGS="-fPIC -D__MUSL__=1"

# Build openssl
curl -L -O https://github.com/openssl/openssl/releases/download/openssl-3.0.9/openssl-3.0.9.tar.gz
tar -zxf openssl-3.0.9.tar.gz
cd openssl-3.0.9/
./Configure --prefix=/opt/openssl-3.0.9-ohos-arm64 linux-aarch64
make -j$(nproc)
make install
cd ..

# Build zlib
curl -L -O https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz
tar -zxf zlib-1.3.1.tar.gz
cd zlib-1.3.1
./configure --prefix=/opt/zlib-1.3.1-ohos-arm64
make -j$(nproc)
make install
cd ..

# Build curl. Static linking with libcurl but dynamic linking with other libraries(libc, openssl, zlib).
curl -L -O  https://curl.se/download/curl-8.8.0.tar.gz
tar -zxf curl-8.8.0.tar.gz
cd curl-8.8.0/
./configure \
    --host=aarch64-linux \
    --prefix=/opt/curl-8.8.0-ohos-arm64 \
    --enable-static \
    --disable-shared \
    --with-openssl=/opt/openssl-3.0.9-ohos-arm64 \
    --with-zlib=/opt/zlib-1.3.1-ohos-arm64 \
    --with-ca-bundle=/etc/ssl/certs/cacert.pem \
    --with-ca-path=/etc/ssl/certs \
    CPPFLAGS="-D_GNU_SOURCE"
make -j$(nproc)
make install
cd ..

# Remove old files if exists
rm -rf curl-8.8.0-ohos-arm64

# Copy the build artifacts to the current directory
cp -r /opt/curl-8.8.0-ohos-arm64 ./

# Clean up
rm -rf *.tar.gz openssl-3.0.9 zlib-1.3.1 curl-8.8.0
rm -rf /opt/ohos-sdk /opt/openssl-3.0.9-ohos-arm64 /opt/zlib-1.3.1-ohos-arm64 /opt/curl-8.8.0-ohos-arm64

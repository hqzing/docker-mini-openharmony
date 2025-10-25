#!/bin/bash
set -e

apt update
apt install -y \
    bison \
    ccache \
    default-jdk \
    flex \
    gcc-arm-linux-gnueabi \
    gcc-arm-none-eabi \
    genext2fs \
    liblz4-tool \
    libssl-dev \
    libtinfo5 \
    mtd-utils \
    mtools \
    openssl \
    ruby \
    scons \
    unzip \
    u-boot-tools \
    zip \
    python-is-python3 \
    pkg-config

# Install git-lfs for downloading the OpenHarmony source code.
curl -L -O https://github.com/git-lfs/git-lfs/releases/download/v3.7.0/git-lfs-linux-amd64-v3.7.0.tar.gz
tar -zxf git-lfs-linux-amd64-v3.7.0.tar.gz
cd git-lfs-3.7.0
./install.sh
cd ..
rm -rf git-lfs-*

# Install the Gitee repo tool for downloading the OpenHarmony source code.
curl -s https://gitee.com/oschina/repo/raw/fork_flow/repo-py3 > /usr/local/bin/repo
chmod a+x /usr/local/bin/repo
pip3 install -i https://repo.huaweicloud.com/repository/pypi/simple requests

# Configure user.name, user.email, and credential.helper for the repo tool.
if [ -z "$(git config --global user.name)" ]; then
    git config --global user.name "test"
fi
if [ -z "$(git config --global user.email)" ]; then
    git config --global user.email "test@test.test"
fi
git config --global credential.helper store

# Download OpenHarmony source code
rm -rf openharmony-source-code openharmony_prebuilts
mkdir openharmony-source-code
cd openharmony-source-code
echo "y" | repo init -u https://gitee.com/openharmony/manifest -b refs/tags/OpenHarmony-v6.0-Release --no-repo-verify
repo sync -c
repo forall -c 'git lfs pull'

# Disable HiLog because the container does not include the HiLog service.
cd third_party/musl/
patch -p1 < ../../../disable-hilog.patch
cd ../../

# Build OpenHarmony operating system image, output in out/rk3568/packages/phone/images/
./build/prebuilts_download.sh
./build.sh --product-name rk3568 --target-cpu arm64

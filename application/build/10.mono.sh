#!/bin/bash
## application/build/10.mono.sh

# Copyright (C) 2015-* Phillip R. Jaenke <talecaster@rootwyrm.com>
#
# NO COMMERCIAL REDISTRIBUTION IN ANY FORM IS PERMITTED WITHOUT
# EXPRESS WRITTEN CONSENT

######################################################################
## Function Import and Setup
######################################################################

. /opt/talecaster/lib/deploy.lib.sh

buildname="mono"

## Build
vbpkg="mono_build"
vbpkg_content="git gcc g++ autoconf libtool automake gettext-dev cmake make openssl-dev"
## Runtime
vrpkg="mono_run"
vrpkg_content="curl gettext linux-headers python2 openssl"

curl_cmd="/usr/bin/curl --tlsv1.2 --cert-status --progress-bar -L"
monov="5.4.0.56"

######################################################################
## Install runtime packages first.
######################################################################
echo "[BUILD] Installing runtime dependencies as $vrpkg"
/sbin/apk --no-cache add --virtual $vrpkg $vrpkg_content
check_error $? $vrpkg

## sitecustomize check
cp /opt/talecaster/python/sitecustomize.py /usr/lib/python2.7/site-packages/sitecustomize.py
check_error $? "sitecutomize"
if [ ! -f /usr/lib/python2.7/site-packages/sitecustomize.py ]; then
	echo "$buildname: [FATAL] Missing python2.7/site-packages/sitecustomize.py!"
	exit 2
fi

######################################################################
## Install our build packages.
######################################################################
printf '[BUILD] Entering Mono build phase...\n'
printf '[MONO] Installing build packages...\n'
/sbin/apk --no-cache add --virtual $vbpkg $vbpkg_content
check_error $? $vbpkg

echo "[MONO] Retrieving $monov"
cd /opt/talecaster/build
$curl_cmd https://download.mono-project.com/sources/mono/mono-$monov.tar.bz2 > mono-$monov.tar.bz2 
bunzip2 mono-$monov.tar.bz2
tar xf mono-$monov.tar
rm mono-$monov.tar
cd mono-$monov

echo "[MONO] Configuring..."
./autogen.sh --enable-shared --enable-small-config --disable-maintainer-mode --disable-compile-warnings --prefix=/usr/local
check_error $? "mono_configure"
echo "[MONO] Building..."
make
check_error $? "mono_build"
echo "[MONO] Installing..."
make install
check_error $? "mono_install"

######################################################################
## Clean up after ourselves, because seriously, this is batshit huge.
######################################################################
make clean
cd /root
rm -rf /opt/talecaster/build/mono-$monov
/sbin/apk --no-cache del mono_build

echo "[MONO] Build and install of $monov"
exit 0 

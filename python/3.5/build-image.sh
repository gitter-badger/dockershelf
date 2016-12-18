#!/bin/bash

# Exit early if there are errors and be verbose.
set -ex

# Tell me where we are.
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Some default values.
SUITE="sid"
MIRROR="http://httpredir.debian.org/debian"
SECMIRROR="http://security.debian.org"
PY_SOURCE_TEMPDIR="$( mktemp -d )"
PY_VER_STR="python${PY_VER_NUM}"
PY_VER_NUM_MAJOR="$( echo ${PY_VER_NUM} | awk -F'.' '{print $1}')"

if [ "${PY_VER_NUM}" == "3.2" ]; then
    PIPURL="https://bootstrap.pypa.io/3.2/get-pip.py"
else
    PIPURL="https://bootstrap.pypa.io/get-pip.py"
fi

# This is the list of python packages from debian that make up a minimal
# python installation. We will use them later.
PY_PKGS="${PY_VER_STR} ${PY_VER_STR}-minimal lib${PY_VER_STR} \
    lib${PY_VER_STR}-stdlib lib${PY_VER_STR}-minimal"

# These are the folders of a debian python installation that we won't need.
PY_CLEAN_DIRS="usr/share/lintian usr/share/man usr/share/pixmaps \
    usr/share/doc usr/share/applications"

# Some tools are needed.
DPKG_PRE_DEPENDS="aptitude deborphan debian-keyring"

# These options are passed to make because we need to speedup the build.
DEB_BUILD_OPTIONS="parallel=$(nproc) nocheck nobench"

# Apt: Install pre depends
# ------------------------------------------------------------------------------
# We need to install the packages defined at ${DPKG_PRE_DEPENDS} because
# some commands are needed to download the source code before installing the
# build dependencies.

echo -e "\nInstalling pre dependencies ...\n"
apt-get update
apt-get upgrade
apt-get install ${DPKG_PRE_DEPENDS}

# Python: Download
# ------------------------------------------------------------------------------
# We will use Debian's internal procedure to download the python source code.
# Python ${PY_VER_NUM} source code is available on ${PY_DEBIAN_SUITE}, so
# we will apt-get source it.
# This will give us all the necessary code to build python. Using this method
# is recommended as it was coded by a Debian Developer who already knows what
# he's doing. Not like me.

echo -e "\nDownloading python source ...\n"
cat > /etc/apt/sources.list << EOF
deb ${MIRROR} ${PY_DEBIAN_SUITE} main
deb-src ${MIRROR} ${PY_DEBIAN_SUITE} main
deb ${MIRROR} ${PY_DEBIAN_SUITE}-updates main
deb ${SECMIRROR} ${PY_DEBIAN_SUITE}/updates main
EOF

apt-get update
cd "${PY_SOURCE_TEMPDIR}" && apt-get source ${PY_VER_STR}

# This is the only folder that was uncompressed (I hope) by apt-get source.
# We will use it as our base source directory.
PY_SOURCE_DIR="$( ls -1d ${PY_SOURCE_TEMPDIR}/*/ | sed 's|/$||' )"

# Apt: Install build depends
# ------------------------------------------------------------------------------
# Now we use mk-build-deps of devscripts package to parse the debian/control
# file which declares all build dependencies. This will generate a package 
# depending on them that we will gracefully install with apt-get.

echo -e "\nInstalling build dependencies ...\n"
DPKG_BUILD_DEPENDS="$( apt-get -s build-dep ${PY_VER_STR} | grep "Inst " \
                        | awk '{print $2}' )"
DPKG_DEPENDS="$( aptitude search -F%p $( printf '~RDepends:~n^%s$ ' ${PY_PKGS} ) \
                    | sed "$( printf 's/^%s$//g;' ${PY_PKGS} )" )"
apt-get install ${DPKG_BUILD_DEPENDS}

# Python: Compilation
# ------------------------------------------------------------------------------
# This is the tricky part: we will use the "clean" and "install" targets of the
# debian/rules makefile (which are used to build a debian package) to compile
# our python source code. This will generate a python build tree in the 
# debian folder which we will later process.

echo -e "\nCompiling python ...\n"
cd "${PY_SOURCE_DIR}" && \
    DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS}" make -f debian/rules clean
cd "${PY_SOURCE_DIR}" && \
    DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS}" make -f debian/rules install

# Apt: Remove build depends
# ------------------------------------------------------------------------------
# We need to clear the filesystem of unwanted packages before installing python
# because some files might be confused with already installed python packages.

echo -e "\nRemoving unnecessary packages ...\n"
apt-get purge ${DPKG_BUILD_DEPENDS}
apt-get autoremove

# This is clever uh? Figure it out myself, ha!
apt-get purge $( apt-mark showauto $( deborphan -a -n --no-show-section \
                                        --guess-all --libdevel -p standard ) )
apt-get autoremove

# This too
apt-get purge $( aptitude search -F%p ~c ~g )
apt-get autoremove

apt-get purge ${DPKG_PRE_DEPENDS}
apt-get autoremove

# Python: Installation
# ------------------------------------------------------------------------------
# We will copy only the minimal python installation files that are within the
# ${PY_PKGS} package list. But before that, we will remove documentation and
# other stuff we won't use.

for PKG in ${PY_PKGS}; do
    if [ -d "${PY_SOURCE_DIR}/debian/${PKG}" ]; then
        for DIR in ${PY_CLEAN_DIRS}; do
            rm -rfv "${PY_SOURCE_DIR}/debian/${PKG}/${DIR}"
        done
        (cd ${PY_SOURCE_DIR}/debian/${PKG} && tar c .) | (cd / && tar xf -)
    fi
done

# Linking to make this the default version of python
ln -sfv /usr/bin/${PY_VER_STR} /usr/bin/python

# Apt: Install runtime dependencies
# ------------------------------------------------------------------------------
# Now we will install the libraries python needs to properly function, and also 
# update the distro to ${SUITE}

cat > /etc/apt/sources.list << EOF
deb ${MIRROR} ${SUITE} main
EOF

apt-get update
apt-get install apt
apt-get upgrade
apt-get dist-upgrade
apt-get install ${DPKG_DEPENDS}

# Pip: Installation
# ------------------------------------------------------------------------------
# Let's bring in the old reliable pip guy.

echo -e "\nInstalling pip ...\n"
curl -fsSL ${PIPURL} | python
pip install --no-cache-dir --upgrade --force-reinstall pip

ln -sfv /usr/local/bin/easy_install \
        /usr/local/bin/easy_install${PY_VER_NUM}

ln -sfv /usr/local/bin/easy_install \
        /usr/local/bin/easy_install${PY_VER_NUM_MAJOR}

ln -sfv /usr/local/bin/pip \
        /usr/local/bin/pip${PY_VER_NUM}

ln -sfv /usr/local/bin/pip \
        /usr/local/bin/pip${PY_VER_NUM_MAJOR}

# Final cleaning
# ------------------------------------------------------------------------------
# Buncha files we won't use.

echo -e "\nRemoving unnecessary files ...\n"
find /usr -name "*.py[co]" -print0 | xargs -0r rm -rfv
find /usr -name "__pycache__" -type d -print0 | xargs -0r rm -rfv
rm -rf ${PY_SOURCE_TEMPDIR}
rm -rfv /tmp/* /usr/share/doc/* /usr/share/locale/* /usr/share/man/* \
        /var/cache/debconf/* /var/cache/apt/* /var/tmp/* /var/log/* \
        /var/lib/apt/lists/*
#!/bin/bash
# Not currently used!

set -ouex pipefail

KERNEL_DIR=$(find /usr/lib/modules/ -maxdepth 2 -mindepth 2 \( -type d -o -type l \) -name 'build')

clone_dir="acer-predator-driver"

# Clone the driver code. Use a personal fork so updates to it can be controlled/managed, and tags can be added if necessary.
git clone --depth=1 https://github.com/mtalexan/acer-predator-turbo-and-rgb-keyboard-linux-module ${clone_dir}
pushd ${clone_dir}

# The driver tries to be really fancy and has an install.sh script that does a bunch of pre-checks, then calls
# the Makefile. The Makefile tries to auto-detect things and support lots of extra use cases. None of it works in a bootc
# image build.
# Ultimately, for non-Clang kernels based on Fedora, it comes down to just the usual out-of-tree kernel module build,
# and generating an auto-load drop-in file for modprobe.
make -C ${KERNEL_DIR} M=$(pwd) modules
make -C ${KERNEL_DIR} M=$(pwd) modules_install

# Add the drop-in for modprobe to auto-load the driver on boot.
mkdir -p /etc/modules-load.d
echo "facer" > /etc/modules-load.d/facer.conf

# Install the python control scripts
install -m 544 -Z -t /usr/bin keyboard.py facer_rgb.py
# TODO: Fix the keyboard.py so it looks for facer_rgb.py in the system PATH or the script_dir rather than assuming it's in the calling dir
# TODO: Fix these two scripts to include the #!/usr/bin/env python3 shebang


# Clean up the folder we cloned and built in
popd
rm -r ${clone_dir}

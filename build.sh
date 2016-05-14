#!/bin/sh
#
# Builds cargo using bootstrap.py
VERSION="master"
TARGET="x86_64-unknown-linux-gnu"
BLACKLIST="winapi winapi-build advapi32-sys kernel32-sys"
OPTS="miniz-sys"
rootpath="$(pwd)"
buildpath="build"
cachepath="$rootpath/cache"
echo "clearing $buildpath directory..."
[ -d "$buildpath" ] && rm --preserve-root -r -- "$buildpath"
mkdir -p "$buildpath/out"
mkdir -p "$cachepath"
cd "$rootpath/$buildpath" || exit
git clone git@github.com:rust-lang/crates.io-index
git clone git@github.com:rust-lang/cargo
cd "$rootpath/$buildpath/cargo" || exit
git checkout "$VERSION"
"$rootpath/bootstrap.py" --crate-index "$rootpath/build/crates.io-index" --target-dir "$rootpath/build/out" --no-clone --no-clean --urls-file "$rootpath/build/urls.txt" --target "$TARGET" --blacklist "$BLACKLIST" --include-optional "$OPTS" --patchdir "$rootpath/patches" --download --crate-cache "$cachepath"
[ $? ] || exit
"$rootpath/bootstrap.py" --crate-index "$rootpath/build/crates.io-index" --target-dir "$rootpath/build/out" --no-clone --no-clean --target "$TARGET" --blacklist "$BLACKLIST" --include-optional "$OPTS"

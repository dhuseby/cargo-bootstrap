#!/bin/sh
#
# Builds cargo using bootstrap.py

TARGET="x86_64-unknown-linux-gnu"
BLACKLIST="winapi winapi-build advapi32-sys kernel32-sys"
rootpath="$(pwd)"
buildpath="build"

echo "clearing $buildpath directory..."
[ -d "$buildpath" ] && rm --preserve-root -r -- "$buildpath"
mkdir -p "$buildpath"
cd "$rootpath/$buildpath" || exit
git clone git@github.com:rust-lang/crates.io-index
git clone git@github.com:rust-lang/cargo

cd "$rootpath/$buildpath/cargo" || exit
"$rootpath/bootstrap.py" --crate-index "$rootpath/build/crates.io-index" --target-dir "$rootpath/build/out" --no-clone --no-clean --urls-file "$rootpath/build/urls.txt" --target "$TARGET" --blacklist "$BLACKLIST" --patchdir "$rootpath/patches" --download
[ $? ] || exit

"$rootpath/bootstrap.py" --crate-index "$rootpath/build/crates.io-index" --target-dir "$rootpath/build/out" --no-clone --no-clean --target "$TARGET" --blacklist "$BLACKLIST"

#!/bin/sh
#
# Use after successful run of ./build.sh to update the rpm source package.
# Usage: ./update-rpm-package.sh <path-to-rpm-package-directory>

die() {
	echo "$@"
	exit 1
}

rpmdir="$1"
packagename="$(basename "$1")"
[ -f "$rpmdir/$packagename.spec" ] || die "$rpmdir/$packagename.spec not found"

echo "remove old crates"
rm -f "$rpmdir"/*.crate
echo "add new crates"
cp -r ./cache/*.crate "$rpmdir"

rm -f "$rpmdir/$packagename.spec.$$"
spec_append() {
	echo "$@" >> "$rpmdir/$packagename.spec.$$"
}

spec_append "### Generated crate dependencies ###"
I=100
while read U; do
    spec_append "$(printf "Source%d:    %s\n" ${I} "${U}")"
    I=$((I+1))
done < ./build/urls.txt

update_archive() {
	n=$1
	name=$2
	path=$3
	cwd="$(pwd)"

	cd "$path"
	tarname="$name-git$(git rev-parse --short HEAD).tar.xz"
	git archive --format=tar --prefix=$name/ HEAD | xz >"$tarname"
	cp "$tarname" "$rpmdir"
	spec_append "Source$n:    $tarname"
	cd "$cwd"
}

echo "remove old archives"
rm -f "$rpmdir"/*.tar.xz
update_archive 0 "cargo" "build/cargo"
update_archive 1 "cargo-bootstrap" "."
update_archive 2 "crates.io-index" "build/crates.io-index"

cat "$rpmdir/$packagename.spec.$$" >> "$rpmdir/$packagename.spec"
rm "$rpmdir/$packagename.spec.$$"

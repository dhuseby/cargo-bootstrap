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

spec_header() {
	cat > "$rpmdir/$packagename.spec.$$" <<EOF
#
# spec file for package cargo-bootstrap
#
# Copyright (c) 2016 Michal Vyskocil, michal.vyskocil@opensuse.org
# Copyright (c) 2016 Kristoffer Gronlund, kgronlund@suse.com
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

Name:           cargo-bootstrap
Version:        $1
Release:        1
License:        MIT or Apache-2.0
Summary:        Bootstrap cargo from minimal dependencies
Url:            https://github.com/rust-lang/cargo
Group:          Development/Languages/Other

EOF
}


spec_append() {
	echo "$@" >> "$rpmdir/$packagename.spec.$$"
}

spec_header "$(cd build/cargo; git describe | sed 's/-/+git/' | sed 's/-/./')"

update_archive() {
	n=$1
	url=$2
	name=$3
	path=$4
	cwd="$(pwd)"

	cd "$path"
	tarname="$name-git$(git rev-parse --short HEAD).tar.xz"
	git archive --format=tar --prefix=$name/ HEAD | xz >"$tarname"
	cp "$tarname" "$rpmdir"
	spec_append "# git clone $url"
	spec_append "# git archive --format=tar --prefix=$name/ HEAD | xz >\"$tarname\""
	spec_append "Source$n:    $tarname"
	spec_append ""
	cd "$cwd"
}

echo "remove old archives"
rm -f "$rpmdir"/*.tar.xz
update_archive 0 "https://github.com/krig/cargo-bootstrap.git" "cargo-bootstrap" "."
update_archive 1 "https://github.com/rust-lang/cargo.git" "cargo" "build/cargo"
update_archive 2 "https://github.com/rust-lang/crates.io-index.git" "crates.io-index" "build/crates.io-index"


spec_append "# Crate dependencies"
I=100
while read U; do
    spec_append "$(printf "Source%d:    %s\n" ${I} "${U}")"
    I=$((I+1))
done < ./build/urls.txt

cat >> "$rpmdir/$packagename.spec.$$" <<EOF

BuildRequires:  rustc >= 1.8.0
# cargo-bootstrap
BuildRequires:  python
BuildRequires:  python-dulwich
BuildRequires:  python-pytoml
BuildRequires:  python-requests

# curl-sys
BuildRequires:  libopenssl-devel
BuildRequires:  zlib-devel

# libssh2-sys
BuildRequires:  cmake
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description
Cargo downloads your Rust project’s dependencies and compiles your project.

%prep
%setup -q -n %{name}
%setup -q -n %{name} -D -T -a 1
%setup -q -n %{name} -D -T -a 2

# crates unpacking
mkdir -p cache

EOF

I=100
while read line; do
    spec_append "cp %{SOURCE$I} cache"
    I=$((I+1))
done < ./build/urls.txt
spec_append ""

cat >> "$rpmdir/$packagename.spec.$$" <<EOF
%build

%ifnarch %{ix86}
TARGET_CPU="%{_target_cpu}"
%else
TARGET_CPU="i686"
%endif

mkdir out
bootstrapdir="\$(pwd)"
cd cargo
\$bootstrapdir/bootstrap.py --crate-index "\$bootstrapdir/crates.io-index" --target-dir "\$bootstrapdir/out" --patchdir "\$bootstrapdir/patches" --crate-cache "\$bootstrapdir/cache" --no-clone --no-clean --target "\$TARGET_CPU-unknown-linux-gnu" --blacklist "winapi winapi-build advapi32-sys kernel32-sys" --include-optional "miniz-sys"
cd ..

%install
mkdir -p %{buildroot}%{_libexecdir}/%{name}
mkdir -p %{buildroot}%{_docdir}/%{name}
install -m 0755 out/cargo-0_*_0 %{buildroot}%{_libexecdir}/%{name}/cargo
install -m 0644 cargo/LICENSE-APACHE %{buildroot}%{_docdir}/%{name}
install -m 0644 cargo/LICENSE-MIT %{buildroot}%{_docdir}/%{name}
install -m 0644 cargo/README.md %{buildroot}%{_docdir}/%{name}

%files
%defattr(-,root,root)
%{_libexecdir}/%{name}
%{_libexecdir/%{name}/cargo
%{_docdir}/%{name}
%{_docdir}/%{name}/LICENSE-APACHE
%{_docdir}/%{name}/LICENSE-MIT
%{_docdir}/%{name}/README.md

%changelog

EOF

# Finally, overwrite specfile with new specfile
mv "$rpmdir/$packagename.spec" "$rpmdir/$packagename.spec.$$.bak"
mv "$rpmdir/$packagename.spec.$$" "$rpmdir/$packagename.spec"

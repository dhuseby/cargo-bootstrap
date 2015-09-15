About
=====

This python script is design to do the bare minimum to compile and link the
Cargo binary for the purposes of bootstrapping itself on a new platform for
which cross-compiling isn't possible.  I wrote this specifically to bootstrap
Cargo on [Bitrig](https://bitrig.org).  Bitrig is a fork of OpenBSD that uses
clang/clang++ and other BSD licensed tools instead of GNU licensed software.
Cross compiling from another platform is extremely difficult because of the
alternative toolchain Bitrig uses.

With this script, all that should be necessary to run this is a working Rust
toolchain, Python, and Git.

This script will not set up a full cargo cache or anything.  It works by
cloning the cargo index and then starting with the cargo dependencies, it
recursively builds the dependency tree.  Once it has the dependency tree, it
starts with the leaves of the tree, doing a breadth first traversal and for
each dependency, it clones the repo, sets the repo's head to the correct
revision and then executes the build command specified in the cargo config.

This bootstrap script uses a temporary directory to store the built dependency
libraries and uses that as a link path when linking dependencies and the
cargo binary.  The goal is to create a statically linked cargo binary that is
capable of being used as a "local cargo" when running the main cargo Makefiles.

Dependencies
============

* pytoml -- used for parsing toml files.
  https://github.com/avakar/pytoml

* dulwich -- used for working with git repos.
  https://git.samba.org/?p=jelmer/dulwich.git;a=summary

Both can be installed via the pip tool:

```sh
sudo pip install pytoml dulwich
```

Command Line Options
====================

```
--cargo-root <path>    specify the path to the cargo repo root.
--target-dir <path>    specify the location to store build results.
--crate-index <path>   path to where crates.io index shoudl be cloned
--no-clone             don't clone crates.io index, --crate-index must point to existing clone.
--no-clean             don't remove the folders created during bootstrapping.
--download             only download the crates needed to bootstrap cargo.
--graph                output dot format graph of dependencies.
--target <triple>      build target: e.g. x86_64-unknown-bitrig
--host <triple>        host machine: e.g. x86_64-unknown-linux-gnu
--test-semver          triggers the execution of the Semver and SemverRange class tests.
```

The `--cargo-root` option defaults to the current directory if unspecified.  The
target directory defaults to Python equivilent of `mktemp -d` if unspecified.
The `--crate-index` option specifies where the crates.io index will be cloned.  Or,
if you already have a clone of the index, the crates index should point there
and you should also specify `--no-clone`.  The `--target` option is used to
specify which platform you are bootstrapping for.  The `--host` option defaults
to the value of the `--target` option when not specified.

Examples
========

To bootstrap Cargo on [Bitrig](https://bitrig.org) I followed these steps:

* Cloned this [bootstrap script repo](https://github.com/dhuseby/cargo-bootstrap)
to `/tmp/bootstrap`.
* Cloned the [crates.io index](https://github.com/rust-lang/crates.io-index)
to `/tmp/index`.
* Created a target folder, `/tmp/out`, for the output.
* Cloned the [Cargo](https://github.com/rust-lang/cargo) repo to `/tmp/cargo`.
* Copied the bootstrap.py script to the cargo repo root.
* Ran the bootstrap.py script like so:
```sh
./bootstrap.py --crate-index /tmp/index --target-dir /tmp/out --no-clone --no-clean --target x86_64-unknown-bitrig
```

After the script completes, there is a Cargo executable named `cargo-0_5_0` in
`/tmp/out`.  That executable can then be used to bootstrap Cargo from source by
specifying it as the `--local-cargo` option to Cargo's `./configure` script.

```sh
./configure --local-cargo=/tmp/out/cargo-0_5_0
```

Notes
=====

### FreeBSD

Make sure you do the following:
* Install py27-pip package
* Use pip to install pytoml and dulwich python modules
* Install ca_root_nss package
* Run: ln -s /usr/local/share/certs/ca-root-nss.crt /etc/ssl/cert.pem
* Install cmake, openssl, libssh2, libgit2, and pkgconf packages
* Install gmake for building cargo once you've bootstrapped a local cargo with
  this script.

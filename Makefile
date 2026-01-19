-include .github/local/Makefile.local

PROJECT ?= fcs960k-aic-bluez
CUSTOM_DEBUILD_ENV ?= DEB_BUILD_OPTIONS='parallel=1'
CUSTOM_DEBUILD_ARG ?=
DEB_OUTPUT_DIR ?= $(PWD)/output

.DEFAULT_GOAL := all
.PHONY: all
all: build

.PHONY: devcontainer_setup
devcontainer_setup: pre_build_dep main_build_dep post_build_dep

.PHONY: pre_build_dep
pre_build_dep:

# Main build dependencies - install cross-compilation toolchain and dependencies
.PHONY: main_build_dep
main_build_dep:
	sudo dpkg --add-architecture arm64
	sudo apt-get update
	sudo apt-get install -y crossbuild-essential-arm64 binfmt-support qemu-user-static
	sudo apt-get install -y \
		autoconf automake libtool \
		pkg-config \
		flex bison \
		python3-docutils \
		libglib2.0-dev:arm64 \
		libdbus-1-dev:arm64 \
		libreadline-dev:arm64 \
		libncurses-dev:arm64 \
		libffi-dev:arm64 \
		zlib1g-dev:arm64 \
		libgettextpo-dev:arm64 \
		libexpat1-dev:arm64 \
		libudev-dev:arm64 \
		libical-dev:arm64 \
		libjson-c-dev:arm64 \
		libelf-dev:arm64 \
		git-buildpackage \
		devscripts \
		dh-exec \
		dh-sequence-python3 \
		lintian

# Additional cross-build dependencies for bluez
.PHONY: arm64_crossbuild_dep
arm64_crossbuild_dep:
	sudo apt-get build-dep . -y --host-architecture arm64 || true

.PHONY: post_build_dep
post_build_dep:

.PHONY: test
test:

.PHONY: build
build: pre_build main_build post_build

.PHONY: pre_build
pre_build:
	chmod +x debian/rules

.PHONY: main_build
main_build:

.PHONY: post_build
post_build:

# distclean target - for cleaning everything
.PHONY: distclean
distclean: clean

# clean target - called by debuild
.PHONY: clean
clean:
	rm -rf debian/.debhelper debian/$(PROJECT)*/ debian/tmp/ debian/debhelper-build-stamp debian/files debian/*.debhelper.log debian/*.*.debhelper debian/*.substvars
	# Call upstream Makefile distclean if it exists
	-if [ -f Makefile ]; then \
		$(MAKE) -f Makefile distclean 2>/dev/null || true; \
	fi
	rm -rf autom4te.cache aclocal.m4 compile config.guess config.h.in config.sub configure depcomp install-sh ltmain.sh missing test-driver

.PHONY: clean-deb
clean-deb:
	rm -rf debian/.debhelper debian/$(PROJECT)*/ debian/tmp/ debian/debhelper-build-stamp debian/files debian/*.debhelper.log debian/*.*.debhelper debian/*.substvars

.PHONY: clean-build
clean-build:
	-if [ -f Makefile ]; then \
		$(MAKE) -f Makefile distclean 2>/dev/null || true; \
	fi
	rm -rf autom4te.cache aclocal.m4 compile config.guess config.h.in config.sub configure depcomp install-sh ltmain.sh missing test-driver

.PHONY: dch
dch: debian/changelog
	gbp dch --ignore-branch --multimaint-merge --release --spawn-editor=never \
		--git-log='--no-merges --perl-regexp --invert-grep --grep=^(chore:\stemplates\sgenerated)' \
		--dch-opt=--upstream --commit --commit-msg="feat: release %(version)s"

.PHONY: deb
deb: debian pre_debuild debuild post_debuild

.PHONY: pre_debuild
pre_debuild:
	# Create output directory
	mkdir -p output
	# Set cross-compiler environment variables
	$(eval export CC=aarch64-linux-gnu-gcc)
	$(eval export CXX=aarch64-linux-gnu-g++)

.PHONY: debuild
debuild:
	$(CUSTOM_DEBUILD_ENV) CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ debuild --no-lintian --lintian-hook "lintian --fail-on error,warning --suppress-tags-from-file $(PWD)/debian/common-lintian-overrides -- %p_%v_*.changes" --no-sign -b $(CUSTOM_DEBUILD_ARG)

.PHONY: post_debuild
post_debuild:

.PHONY: release
release:
	gh workflow run .github/workflows/new_version.yaml --ref $(shell git branch --show-current)

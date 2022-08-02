This set of scripts are targeted for building AT 7.0 and up. If you intend to build any of the prior AT versions (AT 6.0 and below), You should use the old script set. One exception to this is ppc476, which is build by this set of scripts too.

This README comprises the following topics:

1. Requirements
   1.1. Distros
   1.2. Packages
2. Directory structure
   2.1. Main source skeleton
   2.2. Temporary build skeleton
3. Build instructions
   3.1. One command build "do-it-all" approach
   3.2. Fetch pristine sources
   3.3. Build packages
   3.4. Pack everything


1. Requirements:
================
Although the script was designed to run in any distro, the task of a toolchain generation is an Herculean one. And unlike some people may think, a toolchain has a lot of dependencies for its build. We will list below the package requirements and supported distros that our "configsets" impose on our Advance Toolchain (AT) build process.

1.1. Distros:
=============
Depending on the AT version being built, our "configsets" support a set of distros. Some of them are related below:
- AT 7.x: RedHat 6, SuSE 11, Fedora 18 and Ubuntu LTS (actual 12.04 and planned 14.04).
- ppc476: RedHat 6, SuSE 11, Fedora 18 and Ubuntu LTS (actual 12.04 and planned 14.04).
The build will be targeted to the distro being used to build it. This means that a build done on a RedHat will generate rpm packages compatible with RedHat packages.
By compatibility with the building distro, we mean that the AT being build will depend (as little as possible) on the packages provided by that particular distro.

1.2. Packages:
==============
There are some packages that are required for any kind of development on any distro (assembler, linker, compiler, etc). Besides them, there are some other packages specifically needed by a toolchain build (math and floating point libs, etc), and yet some others required by some of the packages that we pack inside our AT distro (basically dependency libs like expat). The build scripts usually check their availability on the build machine, but instead of trying a build and
see it miserably fail, asking for these packages, we provide the list below for your convenience:

	autoconf
	automake >= 1.10
	libtool
	m4
	BASH (bourne again shell)
	CVS client
	rsync
	rpm
	rpmbuild
	bison
	awk
	sed
	flex
	flex-64bit
	All gcc rpms including devel and 64 bit.
	All glibc rpms including devel and 64 bit.
	All binutils rpms including devel and 64 bit.
	Subversion client - With Neon support
	texinfo-4.8-22 - Required for binutils which needs 'makeinfo'.
	perl - for running Uwe Gansert's create_package_descr script
	ncurses - provides the termcap information needed by GDB
	ncurses-devel - provides the termcap information needed by GDB
	terminfo - just to be sure.
	openssl - required header files
	openssl-64bit - required header files
	openssl-devel - required header files
	openssl-devel-64bit - required header files
	expect - For GDB
	python - For GDB
	python-urlgrabber - for createrepo
	rpm-python - for createrepo
	createrepo
	gpg
	popt-devel - for oprofile
	popt-devel-64bit - for oprofile
	qt-devel - for oprofile
	qt-devel-64bit - for oprofile
	libxslt - for valgrind
	libxslt-devel - for valgrind
	docbook-xsl-stylesheets - for valgrind
	git client - for GLIBC checkout (repo migrated from CVS to git)
	java-1_5_0-ibm-devel - for oprofile
	xmllint
	lsb-release
	bzip2-devel
	imake or xorg-x11-utils (for OpenSSL)
	papi-devel - for oprofile
	papi-devel-64bit - for oprofile
	xz-devel/liblzma-dev - for GDB to decompress some debuginfo sections

  Special cases:
    RHEL 5 and SLES 10 only provide older versions of some
    packages. So it's necessary to manually build and install them.
    Make sure they are always installed in /usr/local.

    List of manually installed packages on RHEL 5 and SLES 10:
	automake >= 1.10
	autoconf >= 2.60
	libtool >= 2.2.4
	m4 >= 1.4.9
	flex >= 2.5.37

   After installing automake, it is necessary to configure it by running the following command:
	echo '/usr/share/aclocal/' > /usr/local/share/aclocal/dirlist

Also verify if libstdc++ and libsupc++ are installed in /usr/lib and /usr/lib64.
If any of them is missing, please copy them from /usr/lib/gcc/<arch>-<distro>/<version>/ and /usr/lib/gcc/<arch>-<distro>/<version>/64/ to /usr/lib and /usr/lib64 respectively.



2. Directory structure:
=======================
The build process assemble some directory hierarchies once its tar file is expanded. This hierarchy is really simple, with its structure defined in section 2.1. Once the build is started it creates a series of other working and temporary directories described in section 2.2. On both cases, we are assuming a root sandbox area named <build_root> that is the base for your builds and that you had previously created in an area that you have write access.

2.1. Main source skeleton
=========================
Right after expanding the tarball file with the build scripts, you should have the following directory hierarchy inside your <build_root>:

<build_root>/configs/
<build_root>/scripts/
<build_root>/Makefile
<build_root>/README.txt
<build_root>/README-x86.txt

The most important places that we must check for are those two folders (configs and scripts). These two comprises the whole build system. As the name suggests, the configs directory hold all the supported "configsets" that guides the build scripts present in the scripts directory. If you take a look inside configs, you'll see a series of another directories there, named after the AT versions that we support. They are:

<build_root>/configs/6.0/
<build_root>/configs/7.0/
<build_root>/configs/7.1/
<build_root>/configs/ppc476-tools

Although there is a folder named 6.0, we don't use it to build AT 6.0. It's there for historical reasons and it serves as a basis for all the other configsets (7.0, 7.1 and ppc476-tools). Don't mess with it's files content's unless you know exactly what you're doing. As many of these files are referenced inside the other configsets, you may inadvertently broke other configsets by changing anything on them.
Also, if you are altering some package config file inside your actual configset, be sure to "materialize" that file before performing the change (more information about what is it and how to do so can be found *here[wiki-page-url]*).
Now, lets take a quick look inside a configset directory to find out how it's assembled. We will use a <configset_root> to represent it, but it could be any of the configsets that we have (7.0, 7.1 or ppc476-tools).

<configset_root>/arch/
<configset_root>/distros/
<configset_root>/packages/
<configset_root>/release_notes/
<configset_root>/specs/
<configset_root>/base.mk
<configset_root>/build.mk
<configset_root>/sanity.mk

Each and every configset must have this structure/files to assure that the build system framework will interpret them correctly to produce the proper build. Lets step over each of them with a brief overview of its purpose.

- arch directory and files
  The arch directory contains a series of files, being the most important of them the default.mk and i686.mk, which are used to prepare concise instructs for the build script framework, and they are used indirectly (included) by the other files present there, which follows the template <host_arch>.<target_arch>.mk name. These files have specific information for the given combination of architectures used in the build process. For more information about the contents of these files, check *here[wiki-page-url]*.

- distros directory and files
  The distros directory contains a series of files, which are used to define some important information about the distro being supported in the build process. They follow the naming template <distributor_id>-<release>.mk (all low caps) of the distro as exposed by 'lsb_release -a' command. It contains required distro specific information used by the build and packing processes. The build of this configset is *only* supported by the distros contained here.

- packages directory
  The packages directory contains a series of directories, each of them specific to the package being included in the build of this configset. Each package sub directory holds a set of files used to instruct the pristine source fetch, all the build stages of the package and all the dependencies of this package related to the others that make up this configset. These files are:

  <configset_root>/packages/<package_name>/<package_name>.mk
  <configset_root>/packages/<package_name>/sources
  <configset_root>/packages/<package_name>/specfile
  <configset_root>/packages/<package_name>/stage_<stage_id>

  All of these files are required to define a package for build inclusion, so lets check what each of them holds...

  . <package_name>.mk holds the dependency information of the package related to other stages or packages present in this configset.
  . sources holds information about package version, name, description, documentation URL, pristine fetch URL, patches to apply and from where to grab them.
  . specfile holds information about the package usable for the granular AT package generation.
  . stage_<stage_id> holds some standard functions that instruct the build process for that specific <stage_id>.

- release_notes directory
  The release_notes directory holds template parts used to build the whole release_notes.html file. If there are some changes required by this configset release, it should be done in those templates.

- specs directory
  The specs directory holds base templates for the specfiles used on rpm package build stage. This folder should have at least the files main.spec, monolithic.spec and monolithic_cross.spec. These set of files are used as templates to build the monolithic spec file, as well as the monolithic cross spec file. There are some other files planned to be there, related to the granular spec file/package generation, but they are still just a planned feature.

- base.mk file
  This file contains information about the AT version being build, if it's an alpha, a release candidate internal release, or a final public release. It also contains a set to change the final name location of the AT install directory (usually inside /opt).

- build.mk file
  This file contains information about the general build options used to build AT. This includes some standard gcc support options, which is the base processor architecture being supported, which processors architecture where will be optimizations available and which policy of package generation will be used (today we only support monolithic).

- sanity.mk file
  This file contains a macro definition to perform general sanity checks at the beginning of the build process. It should check for general requirements on the build system in order to run the build. Any package or program check required by the build should be set on the distro specific sanity check, not here.


2.2. Temporary build skeleton
=============================
Once you start a build, the script framework creates two very specific directories related to the configset being built as well as the host architecture and the distro that it uses. One of them is clearly a temporary place where all the temporary installs are made, and its name is tmp.at<at_release>.<distro>_<host_architecture>. The directory name for a build of AT 7.1-0 alpha1 on a powerpc64 machine running SuSE 11 would be named as tmp.at7.1-0-alpha1.suse-11_ppc64. Inside of this directory every package install is done inside a subdirectory named like <package_name>_<stage_id>. For example, binutils stage 1 is installed inside a directory named binutils_1. The path structure on the temp directory is:

<at_temp_area>/<package_name>_<stage_id>

For the normal work area, the named is the same as the temp one, but without the tmp. prefix, so it follows this template at<at_release>.<distro>_<host_architecture>. This folder holds the directory where all the packages are built, the directory where all the packages sources' are prepared (copied and patched), the directory where all stages receipts of the completed steps are saved (for dependency tracking by make), the directory where all the logs, for all building stages are saved, and finally a directory where the final rpm/deb packages are saved and a directory where the final tarball with all the distributable sources is saved. These paths are:

<at_work_area>/builds   - This one holds the component package builds
<at_work_area>/logs     - This one holds the log files of the build
<at_work_area>/receipts - This one holds the control receipts used by make dependency control
<at_work_area>/rpms     - This one holds the generated final packages (rpm/deb)
<at_work_area>/sources  - This one holds the packages patched source files
<at_work_area>/tarball  - This one holds the final generated sources tarball


3. Build instructions:
======================
The build framework is activated by a normal make, with some specific parameters to indicate options to be used for the build. The almost mandatory option is the AT_CONFIGSET parameter to indicate which configset to use for the build. The make has a lot of targets available, including some special isolated targets, like "fetch" to try to grab all the pristine sources and defined patches again. I'll list below some of the options available:

- Special targets:
  all: perform all the required steps from fetch to package build
  fetch: perform only the fetch stage
  toolchain: build only the packages required for the base toolchain

- Additional parameters:
  AT_CONFIGSET: inform the configset to use for the build
  DESTDIR: inform an alternate place to base and install everything
  BUILD_ARCH: inform the target architecture to generate the toolchain

- Examples:
  # Fetches all sources defined on configset 7.0
  make fetch AT_CONFIGSET=7.0

  # Perform all required steps to build AT but base and install it on ${PWD}/work (${PWD}/work will be like the "chroot" of this build). It's only usefull on *test builds*.
  make all AT_CONFIGSET=7.0 DESTDIR=${PWD}/work


3.1. One command build "do-it-all" approach
===========================================
The simplest way of building AT with a single command would be something like this:

# For normal builds
make all AT_CONFIGSET=<configset_name> -j16

# For test builds (used only to validate changes in the configset)
make all AT_CONFIGSET=<configset_name> DESTDIR=<path_to_root_build_area> -j16

Note: If your system have cores and memory available, I highly recommend the usage of make's -j<jobs> option with the highest number possible on it. This will really speedup the build. Note that -j16 in these examples is merely illustrative.


3.2. Fetch pristine sources
===========================
Sometimes you don't have a fast internet connection available, and fetching a lot of different packages from different sources my slow it down to a craw... In this case, I recommend the usage of another approach, with individual commands for each step of the build. In such case, it's better to do a sequential fetch prior to attempt the full parallel build. For such situations, use this command for a single, sequential fetch operation:

# For normal builds
make fetch AT_CONFIGSET=<configset_name>

# For test builds (used only to validate changes in the configset)
make fetch AT_CONFIGSET=<configset_name> DESTDIR=<path_to_root_build_area>


3.3. Build packages
===================
Once the pristine sources and the required patches were fetched, you can go on and request the AT build by issuing the following command:

# For normal builds
make build AT_CONFIGSET=<configset_name> -j16

# For test builds (used only to validate changes in the configset)
make build AT_CONFIGSET=<configset_name> DESTDIR=<path_to_root_build_area> -j16

This single command will try to complete all the required dependencies to perform the build, and deliver a complete AT package into the default "/opt/atX.X" directory, or into the requested DESTDIR directory.
Keep in mind that it will be nice to adjust your -j<jobs> make parameter to you building hardware to take full advantage of it and decrease the required build time.

Note: If you find a problem on the build stage (or any other stage as well), you can try to understand what went wrong by looking at the log files at <at_work_area>/logs. It's highly possible that the build problem is reported there. If you need to send those logs (with more info related) to someone else, just use the following command:

# To collect build logs (normal build)
make collect AT_CONFIGSET=<configset_name>

# To collect build logs (test build)
make collect AT_CONFIGSET=<configset_name> DESTDIR=<path_to_root_build_area>


3.4. Pack everything
====================
The package target has a single recipe, so it doesn't take advantage of the -j<jobs> option. This target generates rpm packages on RedHat like distros (RedHat, CentOS, Fedora), and deb packages on Debian like distros (Debian, Ubuntu).

# For normal builds
make package AT_CONFIGSET=<configset_name>

If you need to provide a release-notes.html to the final AT release, run the following command to have it built and ready for release:

# For normal builds
make release AT_CONFIGSET=<configset_name>

After the package process, you will find the following listed packages (full path) ready for standalone installation, or repository addition:

<at_work_area>/{rpms,debs}/ppc64/advanced-toolchain-atX.Y-runtime-X.Y-Z.ppc64.{rpm,deb}
<at_work_area>/{rpms,debs}/ppc64/advanced-toolchain-atX.Y-devel-X.Y-Z.ppc64.{rpm,deb}
<at_work_area>/{rpms,debs}/ppc64/advanced-toolchain-atX.Y-perf-X.Y-Z.ppc64.{rpm,deb}
<at_work_area>/{rpms,debs}/ppc64/advanced-toolchain-atX.Y-mcore-X.Y-Z.ppc64.{rpm,deb}
<at_work_area>/{rpms,debs}/ppc64/advanced-toolchain-atX.Y-selinux-X.Y-Z.ppc64.{rpm,deb}




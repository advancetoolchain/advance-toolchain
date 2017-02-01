Note: the build scripts only run on SLES 10 (and its Service Pack updates) and
on RHEL5 (and its update releases) for the Advance Toolchain 5.0 and below. For
Advance Toolchain 6.0 and above, the build scripts only run on SLES 11 (and its
Service Pack updates) and RHEL6 (and its update releases).

Dependencies:

  The best way to prevent dependency problems is to just install
  everything.  Toolchain builds have a million dependencies.  The
  following are the known dependencies:

	autoconf
	automake
	libtool
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
	git client - for GLIBC checkout (repo migrated from CVS to git)

Also verify if libstdc++ and libsupc++ are installed in /usr/lib and /usr/lib64.
If any of them is missing, please copy them from /usr/lib/gcc/<arch>-<distro>/<version>/
and /usr/lib/gcc/<arch>-<distro>/<version>/64/ to /usr/lib and /usr/lib64 respectively.

Directory Layout (creation sequences described in next section):
--------------------------------------------------------------------------
# The Advance Toolchain base directory where toolchains are built:
/<path-to>/at

# Build scripts directory:
/<path-to>/at/scripts/

# Patches directory:
/<path-to>/at/patches/

# Sources directory:
/<path-to>/at/sources/

# Working directory for a particular AT version build.  Scripts that have
# to be modified for a particular build version are stored here as well.
/<path-to>/at/atX.Y-Z/

# Sources are copied to this location and patched by the build script:
/<path-to>/at/atX.Y-Z/src/

# Sources are built in this directory:
/<path-to>/at/atX.Y-Z/build/

# Where the binary .rpm files are located after rpmbuild:
/<path-to>/at/atX.Y-Z/rpms/

# Where the build stages log files located after a build:
/<path-to>/at/atX.Y-Z/logs/

# Powerpc-cpu installs are done here temporarily before they're copied to
# the toolchain destination directory.
/<path-to>/at/atX.Y-Z/install/

# Where the toolchain is always installed (Note, subsequent rebuilds of the
# advance toolchain will overwrite the previous toolchain in /opt/atX.Y).
/opt/atX.Y/

Requirements:
	/<path-to>/at-YYYYMMDD.tgz
	/<path-to>/README.txt

UIUC NCSA Build Topography:

	buildbox - This host is on a private network and the only
		network connection to it is ssh/scp to/from lbuild.
		buildbox has lots of local disk. It only has one user
		on it, root.  This machine executes the toolchain
		build.

	lbuild - Fully Internet connected box. Also has read and write
		access to AFS (a networked filesystem).  Connect
		to this host use userids, not root.  Repository
		creation and update scripts run on this machine.

	linuxpatch.ncsa.uiuc.edu - Fully Internet connected box.  It's
		the ftp server and it serves data out of the AFS
		filesystem starting at
		/afs/ncsa.uiuc.edu/ftp/lpatch/pub if anonymously
		connected or /afs/ncsa.uiuc.edu/ftp/lpatch/ if
		connecting with ftp using the lpatch account.

Preconditions:

User Steps:
--------------------------------------------------------------------------
1.)  Determine where you want the Advance Toolchain base directory to be
     located.  The base directory is where all toolchains will be built.
     A good location would be $HOME/at/.  Create this directory, e.g.

	mkdir -p $HOME/at

2.)  Change directory to the Advance Toolchain base directory that you just
     built.  Unpack the archive elements using the following tar extract
     command.  It is essential that this be done in the Advance Toolchain
     base directory:

	cd $HOME/at
	tar -xzf /<path-to>/at-YYYYMMDD.tgz ./configs ./scripts ./patches

3.)  Verify the +x execute permissions on the scripts in the scripts
     directory ($HOME/at/scripts) for this user.  Update the scripts with
     chmod +x if they're not set to have execute permissions.

4.)  Verify that the current working directory is the Advance Toolchain
     base directory $HOME/at/.  From the Advance Toolchain base directory
     invoke the 'pre.sh' script with the following parameters:
        1.) The path to the config.at file
        2.) The path to the at build base directory

	cd $HOME/at/
	$HOME/at/scripts/pre.sh $HOME/at/configs/<config_file> $PWD

     Based upon the <config_file> file this will determine if new sources need
     to be downloaded into the Advance Toolchain base directory's 'sources'
     directory. The <config_file> name is specified in the build request e-mail.

     NOTE: The 'pre.sh' script will tell you which directory it created for
     you to do the next versioned toolchain build in, e.g.

	$HOME/at/at5.0-1

------------------------------------------------------------------------------
If you're fetching sources on a system that is different than the one
that will be doing the build, pay attention that pre.sh freezes the current
distro and version to be used, so if it was ran on a RedHat 5, the build must
happen on that distro and will be rejected by subsequent scripts on any other
one. Also, performimg fetch on anything other than RHEL or SLES will be rejected
by the scripts. With that said, do the following step:

4.1) On the prefetch machine make sure you're in the Advance Toolchain base
     directory:

	cd $HOME/at

4.2) Archive the Advance Toolchain base directory:
	tar -czf $HOME/at-`date +%Y%m%d`.tgz ./

4.3) Copy the archive to the build machine under the exact same username as
     that used to run the pre.sh script on the prefetch machine.

4.4) Create the Advance Toolchain build directory in the EXACT SAME PLACE
     on the build machine as where it was located on the prefetch machine.

	mkdir $HOME/at

4.5) Change directory to the Advance Toolchain build directory:

	cd $HOME/at

4.6) Unpack the Advance Toolchain base directory in the exact same place
     where it was packed but on the build machine:

	tar -xzf /<path-to>/at-<date>.tgz ./

------------------------------------------------------------------------------

5.)  Change directory to the newly created directory for this build indicated
     by the 'pre.sh' script highlighted above, i.e.

	cd $HOME/at/at5.0-1

     NOTE: The 'pre.sh' script also created a unique self-contained wrapper
     script in this directory called 'at.sh'.  This was constructed from
     script fragments and the information in the <config_file> file.

6.)  Kick off the versioned toolchain build by invoking the local 'at.sh'
     wrapper script, e.g.
	sh at.sh

     Log files are kept in $HOME/at/atX.Y-Z/logs/

     A Binary RPM is created and placed in the 'rpms' directory off the
     current build directory:
	$HOME/at/atX.Y-Z/rpms/ppc64/advanced-toolchain-atX.Y-cross-X.Y-Z.ppc64.rpm

     RPMs install into the 'AT_DEST' directory indicated in the config.at file, e.g.
	/opt/at5.0/

7.)  Copy the original script archive onto lbuild.  Unpack the config
     directory and scripts directory on said server in the exact same
     place where you placed it on buildbox.

	mkdir $HOME/at
	cd $HOME/at
	tar -xzf /<path-to>/at.tgz ./configs ./scripts

8.)  Copy the resultant rpms onto lbuild in the exact same place they
     were installed by the build scripts on the buildbox, i.e.

       $HOME/at/at5.0-1/rpms/ppc64/

9.) For good measure copy the log files from the buildbox to lbuild.
    This way if they need to be collated you have them all in one
    place.

       $HOME/at/atX.Y-Z/logs

10.) The cross-compiler RPM currently does not need to be signed.

11.) The cross-compiler RPM should be manually copied to the repository. i.e.
	 If it is a SLES10 build, then it should go into
	
		/afs/ncsa.uiuc.edu/ftp/lpatch/toolchain/at/suse/SLES_10/atX.Y/

Congratulations there should now be a cross-compiler RPM into the designated
Linux distribution repository.

12.) Copy the generated build logs to the private FTP server and make
	 it available for further reference. i.e.
	
	 cp $ATHOME/at5.0-5/logs_2012-06-21 00:55:31-05:00.tar.gz \
	    /afs/.ncsa/ftp/lpatch/private/toolchain/logs_[buildnumber].tar.gz
	
	  Include a link to this log file in the e-mail notification when
	  the build is done.

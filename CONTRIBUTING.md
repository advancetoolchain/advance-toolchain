# Process For Accepting Third Party Code Contributions

To improve tracking of contributions to this project we will use a process
modelled on the modified DCO 1.1 and use a "sign-off" procedure on patches that
are being emailed around or contributed in any other way.

The sign-off is a simple line at the end of the explanation for the patch,
which certifies that you wrote it or otherwise have the right to pass it on as
an open-source patch.  The rules are pretty simple: if you can certify the
below:

	Developer's Certificate of Origin 1.1

	By making a contribution to this project, I certify that:

	(a). The contribution was created in whole or in part by me and I
	have the right to submit it under the open source license
	indicated in the file; or

	(b). The contribution is based upon previous work that, to the best
	of my knowledge, is covered under an appropriate open source
	License and I have the right under that license to submit that
	work with modifications, whether created in whole or in part
	by me, under the same open source license (unless I am
	permitted to submit under a different license), as indicated
	in the file; or

	(c). The contribution was provided directly to me by some other
	person who certified (a), (b) or (c) and I have not modified
	it.

	(d). The contribution is made free of any other party's intellectual
	property claims or rights.

	(e). I understand and agree that this project and the contribution
	are public and that a record of the contribution (including all
	personal information I submit with it, including my sign-off) is
	maintained indefinitely and may be redistributed consistent with
	project or the open source license(s) involved.

then you just add a line saying

	Signed-off-by: Random J Developer <random@developer.org>

using your real name (sorry, no pseudonyms or anonymous contributions.)

# Quick HOWTO

1. Make sure you have a [GitHub account](https://github.com/signup/free)

2. Fork the repo.

3. Make the changes and run the testcases. We only take pull requests with
passing tests.

4. If it is applicable, improve or add the current testcases to cover for the
new functionality.

5. Push to your fork and submit a pull request.

After 5. the pull request will be reviewed and checked.  We may suggest some
changes or improvements or alternatives.

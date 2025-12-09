#!/bin/bash
#
# Copyright 2017 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This script opens a config/source file, reads all available repositories
# and change the ATSRC_PACKAGE_REV to the latest revision.
# Afterwards it checks if the sources file on the remote topic branch is
# different from the sources file in the local topic branch. In case it's
# not, there's nothing to be done. Otherwise, the script commits and
# pushes to the remote topic branch on the advance-toolchain fork of the
# provided user.
#
# Remarks:
# - This script uses SSH to push to GitHub, therefore you need
# the appropriate keys of the provided GitHub user.
# - Since this script automatically switches branches, it's
# recommended unstaging or stashing changes before running it.
#
# Usage:
#  update_revision <config/package/source> <github_user> [PAT [signature]]
#
#  Using GitHub, PAT stands for "Personal Access Token", and can be
#  obtained on GitHub Settings > Personal access tokens > Generate new
#  token. For the current features of this script, only the public_repo
#  scope is required to be enabled. In case you choose to omit your token,
#  your topic remote branch will still be updated but no pull request
#  will be opened.
#    By default, this script will use your local git configuration to
#  generate a signed-off-by line automatically for commits, which is
#  required for contributing to AT. You may specify a custom signature
#  as long as you also specify a PAT. Please follow the standard format,
#  which is "your name here <your email here>".

# This script requires 3 or 4 parameters.
if [[ ${#} -lt  2 ]] || [[ ${#} -gt 4 ]]; then
	echo "update_revision.sh expects 2 to 4 parameters."
	exit 1
fi

# TODO: adjust following variables.
# Assume user access GitHub password-lessly
GITHUB_USER=${2}
GITHUB_TOKEN=${3}
GITHUB_SIGNATURE=${4}

source ${1}

# If ATSRC_PACKAGE_CO is not defined, we skip the revision check.
if ! [ -n "${ATSRC_PACKAGE_CO}" ] || ! [ -n "${ATSRC_PACKAGE_REV}" ]; then
	exit 0
fi

if [[ -z "${GITHUB_SIGNATURE}" ]]; then
	GIT_USER=$(git config --global user.name)
	GIT_EMAIL=$(git config --global user.email)

	if [[ "${GIT_USER}" = "" ]] || [[ "${GIT_EMAIL}" = "" ]]; then
		echo "Error: Git's user.name or user.email not configured."
		exit 1
	fi
fi

# This function print a message with indentation
#
# Parameters:
#     $1 - indentation level. Any integer number greater or equal to zero.
#     $2 - the message.
print_msg ()
{
	for ((i=0;i<${1};i++)); do
		echo -n '-'
	done
	echo ${2}
}

# This function makes a request to the GitHub REST API. It returns the HTTP
# status code for the request and saves any output to outfile. Any
# extra parameters are passed directly as arguments to curl.
#
# Parameters:
#     $1 - outfile
#     $2 - endpoint
ghapi_call ()
{
	if [[ ${#} -lt 2 ]]; then
		echo "Function ghapi_call expects at least 2 parameters."
		return 1
	fi

	outfile="${1}"
	url="https://api.github.com/${2}"
	shift 2

	curl ${url} -si -o ${outfile} -w '%{http_code}' \
	     -H "Authorization: Bearer $GITHUB_TOKEN" \
             -H "Content-Type: application/vnd.github+json" \
             -H "X-GitHub-Api-Version: 2022-11-28" ${@}
}

# This function makes a request to the GitHub GraphQL API. It returns the HTTP
# status code for the request and saves any output to outfile. Any
# extra parameters are passed directly as arguments to curl.
#
# Parameters:
#     $1 - outfile
#     $2 - input file (containing the JSON payload)
ghapi_gql_call ()
{
	if [[ ${#} -lt 2 ]]; then
		echo "Function ghapi_gql_call expects at least 2 parameters."
		return 1
	fi

	outfile="${1}"
	jsonfile="${2}"
	url="https://api.github.com/graphql"
	shift 2

	curl ${url} -s -X POST -o ${outfile} -w '%{http_code}' \
	     -H "Authorization: Bearer $GITHUB_TOKEN" \
             -H "Content-Type: application/vnd.github+json" \
             -H "X-GitHub-Api-Version: 2022-11-28" \
             -d "@${jsonfile}" ${@}
}

# This function returns the latest revision from a git/svn repository
#
# Parameters:
#    $1 - URL to reach source code
#    $2 - package
#    $3 - configset
get_latest_revision ()
{
	if [[ ${#} -ne 3 ]]; then
		echo "Function get_latest_revision expects 3 parameters."
		return 1
	fi

	local url=${1}
	local package=${2}
	local configset=${3}
	local isGit=$(echo ${url} | grep -ce "git:" -e "\.git$")
	local hash=""

	if [[ "${isGit}" == 1 ]]; then
		local tmp_dir=$(mktemp -d)
		git clone ${url} ${tmp_dir}
		pushd ${tmp_dir} > /dev/null
		# Check for the remote HEAD reference.
		if [[ ! -e .git/refs/remotes/origin/HEAD ]]; then
			# Fix missing reference.
			git remote set-head origin master
		fi
		# Since GCC moved to git (January 2020), extra git commands have
		# been needed to get IBM branches.
		if [[ $package == "gcc" ]] && [[ $configset != "next" ]]; then
		    git config --local remote.origin.fetch +refs/vendors/ibm/heads/*:refs/remotes/origin/ibm/*
		    git fetch origin
		fi
		# Get which branch is being used.
		local branch=${ATSRC_PACKAGE_BRANCH}
		[[ -z "$branch" ]] && branch="HEAD"
		# Since GCC moved to git (January 2020), the IBM branches have been
		# relocated within the vendors directory.
		if [[ $package == "gcc" ]] && [[ $configset != "next" ]]; then
		    branch="refs/vendors/ibm/heads/${branch}"
		fi
		hash=$(git ls-remote ${url} ${branch} | cut -f1)
		[[ -n "$hash" ]] && hash=$(git rev-parse --short=12 ${hash})
		popd > /dev/null
		rm -rf ${tmp_dir}
	else
		local isTgz=$(echo ${url} | grep -c "\.tar\.[bg]z")
		if [[ "${isTgz}" == 1 ]]; then
			echo "URL is a tarball, nothing to do."
			return 1
		fi
		# It's not a tarball, let's assume it's a SVN URL
		hash=$(svn info ${url} | grep "Last Changed Rev:" | cut -d: -f2)
	fi

	echo ${hash}
}

# This function returns the version of a package based on a revision.
# It returns an empty string unless the found version isn't the same as
# the current known version.
#
# Parameters:
#    $1 - package
#    $2 - revision
get_version ()
{
	local package=${1}
	local revision=${2}

	if [[ "${ATSRC_PACKAGE_VER}" == "master" ]]; then
		echo ""
		return 0
	fi
        if [[ -z "${ATSRC_PACKAGE_UPSTREAM}" ]]; then
                echo "ATSRC_PACKAGE_UPSTREAM isn't defined for the package $package"
                return 1
        fi
        out=$(eval $(echo "${ATSRC_PACKAGE_UPSTREAM}" | sed "s/__REVISION__/$revision/g"))
	[[ "${ATSRC_PACKAGE_VER}" == "$out" ]] && out=""
	echo "$out"
}

# This function prepares a commit, pushes it and, if a GitHub token
# is supplied, opens a pull request
#
# Parameters:
#    $1 - sources config path
#    $2 - revision ID
#    $3 - version (optional)
send_to_github ()
{
	# Get AT config and package being updated.
	# Expected a string like
	# "<path-to-AT>/configs/<configset>/packages/<package>/source"
	pkg=$(echo ${1} | awk -F "/" '{ print $(NF-1) }')
	cfg=$(echo ${1} | awk -F "/" '{ print $(NF-3) }')

        # Temp file to save output of REST calls to the GitHub API
	out=$(mktemp '/tmp/ghapi-XXXXX.out')
        trap '{ rm -f -- ${out}; }' EXIT

	print_msg 1 "Preparing commit to send for review."

	# Check connection to GitHub
	print_msg 2 "Checking GitHub SSH accessibility."
	ssh git@github.com > /dev/null 2>&1 </dev/null
	if [[ $? -ne 1 ]]; then
		print_msg 0 "Problem accessing GitHub with SSH."
		return 1
	else
		print_msg 0 "SSH is okay."
	fi

	if [[ ! -z "$GITHUB_TOKEN" ]]; then
		print_msg 2 "Checking if the token provided grants pull request creation \
rights"

                status=$(ghapi_call ${out} "user")
		if [[ $? -ne 0 ]]; then
			print_msg 0 "cURL to GitHub API exited with non zero status."
			return 1
		elif [[ ${status} -eq 200 ]]; then
			if [[ $(grep -i 'x-oauth-scopes:' ${out}\
				| grep -cE -e "public_repo" -e "repo([[:cntrl:]]*$|,)") -gt 0 ]]; then
				print_msg 0 "The token provides the necessary rights!"
			else
				print_msg 0 "Please make sure the provided token has the \
public_repo scope enabled."
				return 1
			fi
		else
			print_msg 0 "Unexpected error. Here's the status GitHub API returned: ${status}"
			return 1
		fi

		print_msg 2 "Checking if a pull request to update this package \
already exists, to avoid overwriting."

		searchparamslist=('user:advancetoolchain' \
		'repo:advance-toolchain' \
		'state:open' \
		'type:pr' \
		'in:title' \
		"author:$GITHUB_USER" \
		"Update+${pkg}+on+AT+${cfg}")
		searchparams=$(printf "+%s" "${searchparamslist[@]}")
		searchparams=${searchparams:1}

                status=$(ghapi_call ${out} "search/issues?q=$searchparams")

		if [[ $? -ne 0 ]]; then
			print_msg 0 "cURL to GitHub API exited with non zero status."
			return 1
		elif [[ ${status} -eq 200 ]]; then
			if [[ $(grep -m 1 "total_count" ${out} \
			   | grep -oE "[0-9]+") -gt 0 ]]; then
				print_msg 0 "There already is an open pull request for $pkg on AT \
$cfg. Aborting operation..."
				return 1
			else
				print_msg 0 "No open pull request for this package and configset \
exists!"
			fi
		else
			print_msg 0 "Unexpected error. Here's the status GitHub API returned: ${status}"
			return 1
		fi
	fi
	print_msg 0 "Connection can be established."

	local target_remote=git@github.com:${GITHUB_USER}/advance-toolchain.git
	local target_branch=auto-update_${cfg}_${pkg}

	# Save current branch and switch to a work branch
	#
	current_branch=$(git rev-parse --abbrev-ref HEAD)
	# -B option resets the branch if it already exists.
	git checkout -B ${target_branch}

	# Here we check if the new sources file we generated by updating the
	# revision is different from the sources file at the last commit
	# on the appropriate branch.
	# To do that, we run a git diff between our working tree and the
	# appropriate branch. Since the branch we want to compare to is
	# remote, we need to add a new temporary remote to the repo.
	git remote add TMP_DIFF ${target_remote}
	git fetch TMP_DIFF

	print_msg 2 "Checking ${pkg} revision on the topic branch"

	if [[ $(git ls-remote -h ${target_remote} | grep -c ${target_branch}) = 1 ]] \
		 && git diff --exit-code TMP_DIFF/${target_branch} -- ${1}; then
		print_msg 0 "$pkg revision is already up to date, new commit not necessary"

		git remote remove TMP_DIFF

		git checkout ${current_branch} ${1}
		git checkout ${current_branch}
		return 0
	else
		print_msg 0 "$pkg revision is outdated, continuing commit..."
	fi

	git remote remove TMP_DIFF

	print_msg 2 "Generating a patch"
	file=$(basename $(dirname ${1}))/$(basename ${1})

	local version_str=""
	[[ -n "${3}" ]] && version_str="Bump to version ${3}\n"

	git add ${1}
	local msg="Update ${pkg} on AT ${cfg}\n\n\
${version_str}Bump to revision ${2}\n\n\
\
${GITHUB_SIGNATURE:+Signed-off-by: ${GITHUB_SIGNATURE}}"

	echo -e ${msg} | git commit -s -F -

	# Now we send the commit to GitHub
	print_msg 2 "Sending commit to GitHub"
	git push --force ${target_remote} HEAD:${target_branch}


	if [[ ! -z "$GITHUB_TOKEN" ]]; then
		cat > ${out} <<EOF
{
"title": "Update ${pkg} on AT ${cfg}",
"body": "${version_str}Bump to revision ${2}",
"head": "${GITHUB_USER}:${target_branch}",
"base": "master"
}
EOF

		status=$(ghapi_call ${out} "repos/advancetoolchain/advance-toolchain/pulls"\
				    --data "@${out}")

		if [[ ${status} -eq 201 ]]; then
                        # Enabling auto-merge if the version wasn't updated.
                        if [[ -z "${3}" ]]; then
				print_msg 0 "Pull request creation successful!"
				pr_number=$(grep -oE '"number": [0-9]+' ${out} | cut -d' ' -f2)

				# Enabling auto-merge on a PR is only available through
				# the GraphQL API. First we need to get the PR's id
				cat > payload.json <<EOF
{
  "query": "query FindPullRequestID {
    repository(owner: \"advancetoolchain\", name: \"advance-toolchain\") {
      pullRequest(number: ${pr_number}) {
        id
      }
    }
  }"
}
EOF

				status=$(ghapi_gql_call ${out} 'payload.json')

				if [[ ${status} -eq 200 ]]; then
					pr_id="$(cat ${out} | jq -r '.data.repository.pullRequest.id')"
					echo "PR ID: ${pr_id}"

					cat > payload.json <<EOF
{
  "query": "mutation EnableAutoMerge {
    enablePullRequestAutoMerge(input: {pullRequestId: \"${pr_id}\", mergeMethod: REBASE}){
      actor {
        login
      }
    }
  }"
}
EOF

					status=$(ghapi_gql_call ${out} 'payload.json')

					if [[ ${status} -eq 200 ]]; then
						print_msg 0 "Successfully enabled auto-merge for pull request."
					else
						print_msg 0 "Failed to enable auto-merge for pull request."
						cat ${out}
					fi
				else
					print_msg 0 "Failed to get pull request data."
					cat ${out}
				fi
			fi
		else
			print_msg 0 "Pull request creation failed. cURL message:"
			cat ${out}
		fi
	fi

	# Switch back to original branch
	git checkout ${current_branch}
}

# This function updates a revision.
#
# Parameters:
#    $1 - sources config path
#    $2 - revision ID
#    $3 - version (optional)
update_revision ()
{
	if [[ ${#} -lt  2 ]]; then
		echo "Function update_revision expects at least 2 parameters."
		return 1
	fi

	# TODO: weak check - some revisions have less than 12 chars.
	if [[ ${2} == ${ATSRC_PACKAGE_REV} ]]; then
		print_msg 0 "Sources at latest revision already. Nothing to be done."
		exit 0
	fi

	print_msg 1 "Updating ${1} to the latest revision."
	sed -i -e "s/ATSRC_PACKAGE_REV=.*/ATSRC_PACKAGE_REV=${2}/g" ${1}

	if [[ -n "${3}" ]]; then
		print_msg 1 "Updating ${1} to a new version."
		sed -i -e "s/ATSRC_PACKAGE_VER=.*/ATSRC_PACKAGE_VER=${3}/g" ${1}
	fi

	print_msg 0 "Update complete."
}

package=$(readlink -f $1 | tr "/" "\n" | tail -n 2 | head -n 1)
configset=$(readlink -f $1 | tr "/" "\n" | tail -n 4 | head -n 1)
for co in "${ATSRC_PACKAGE_CO[@]}"; do
	# So far, we only update git/svn revision
	repo=$(echo $co | grep -oE \(git\|svn\|https\):[^\ ]+)

	[[ -z "${repo}" ]] && continue

	hash=$(get_latest_revision ${repo} ${package} ${configset})
	if [[ $? == 0 && -n "${hash}" ]]; then
	    echo ""
	    print_msg 0 "The latest revision of ${repo} is ${hash}"

	    version=$(get_version ${package} ${hash})
	    if [[ $? != 0 ]]; then
		print_msg 0 "Warning: $version"
		version=""
	    fi
	    update_revision ${1} ${hash} ${version}
	    send_to_github ${1} ${hash} ${version}
	    break
	else
	    [[ -n "${hash}" ]] && print_msg 0 "${hash}"
	fi
done

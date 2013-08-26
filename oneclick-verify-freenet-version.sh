#!/bin/sh

# (c) 2013 mempo.org - Released to public domain; Choose any: WTFPL licence; BSD licence;
# opensource@mempo.org - Seriously easy security for everyone

# Goal: This script will download and verify a freenet version (compare the 
# build from downloaded sources with the resulting published binary)
# Purpose: Verifying freenet binary builds (.jar) against binary backdoor
# Method: Just wrap the verify-build with all needed setting up commands

# --- config ----
config_version="$1"
config_basedir_top="$HOME/verify_freenet"
config_basedir="$config_basedir_top/$config_version"

# --- functions ----

script_error() {
	echo "ERROR: There was a problem with this script, unable to do the verification." ; echo "" ; exit 1
}

# --- start ----

if [ -z "$HOME" ] ; then echo "The user HOME is not defined, please define this variable in env."; script_error; fi

if [ -z "$config_version" ] ; then
	echo "Please declare the version to verify as argument to this script, e.g. 1453"	
	script_error
fi

echo ""
echo "---------------------------------"
echo "Will verify Freenet build version $config_version"
echo "Using directory $config_basedir [PRIVATE]" # private, it might be absolute e.g. with username
echo ""
echo "We will use:"
echo "  * download over clear-internet (your IP is seen by ISP and everyone around) !!!"
echo "  * also download from Freenet (need to have Freenet running)"
echo "it will be visible to others that you (IP) are verifing freenet (unless e.g. VM on TOR) "

if [ "$2" != "--no-confirmation-start" ] 
then
	echo "Is that ok? Continue? (y/n)"
	read reply
	if [ "$reply" != "y" ]
	then
		echo "You said to NOT continue - ok aborting"
		script_error
	fi
fi
echo "---------------------------------"


# --- cleanup ----

if [ -d "$config_basedir" ] ; then
	echo "The directory $config_basedir exists, probably from previous verification."
	echo "DELETE THIS DIRECTORY? Write word 'del' if you agree or else to cancel." 
	echo "Delete? (del/n)"
	read reply
	if [ "$reply" != "del" ]
	then
		echo "You said to NOT continue (not deleting this directory) - ok aborting (you can delete it manually and restart)"
		script_error
	fi
	echo "Ok, DELETING this directory"
	rm -rf "$config_basedir" || { echo "Can not delete old dir"; script_error; }
	echo "Deleted."
fi

# --- preparation to verify ----

set -x

mkdir -p "$config_basedir" || { echo "Can not create dir"; script_error; }
cd "$config_basedir" || { echo "Can not enter dir"; script_error; }

git clone git://github.com/freenet/scripts.git || { echo "Can not download from git."; script_error; }

git clone git://github.com/freenet/fred-official.git || { echo "Can not download from git."; script_error; }

git clone git://github.com/freenet/lib-pyFreenet-staging.git || { echo "Can not download from git."; script_error; }

cp scripts/freenetrc-sample ~/.freenetrc || { echo "Can not copy RC"; script_error; }


# XXX debug test
if [ -r "$HOME/CODE/verify-config-path-fix.sh" ] ; then
	cp "$HOME/CODE/verify-config-path-fix.sh" scripts/  # copy your local script
fi


config_script="./scripts/verify-config-path-fix.sh"
if [ -x "$config_script" ] ; then
	$config_script || { echo "Can not configure the .freenetrc"; script_error; } # execute it
else
	set +x
	echo ""
	echo "The configuration script is not used here, you need to yourself edit file ~/.freenetrc"
	echo "... search for variables releaseDir and fredDir and in each replace the ../ with absolute path"
	echo "...of the directory where we build freenet, like $config_basedir/ "
	echo "...this is very easy, or ask us for support if any questions"
	echo "...Enter y when the file was edited by you or n to cancel."
	echo "Did you edited now this file yet? (y/n) (n will cancel)"
	read reply
	if [ "$reply" != "y" ]
	then
		echo "You said to NOT continue (not deleting this directoru) - ok aborting (you can delete it manually and restart)"
		script_error
	fi
	set -x
fi

set -x

mkdir FreenetReleased || { echo "Can not make dir for release "; script_error; }
wget https://downloads.freenetproject.org/alpha/freenet-ext.jar -O FreenetReleased/freenet-ext.jar || { echo "Can not download freenet-ext"; script_error; }
wget http://www.bouncycastle.org/download/bcprov-jdk15on-149.jar -O FreenetReleased/bcprov.jar || { echo "Can not download bcprov "; script_error; }
wget http://amphibian.dyndns.org/flogmirror/mykey.gpg -O toad.gpg || { echo "Can not download GPG key "; script_error; }

gpg --import toad.gpg || { echo "Can not import GPG key"; script_error; }

cd lib-pyFreenet-staging  || { echo "Can not enter pyFreenet dir "; script_error; }
python setup.py install --user || { echo "Can not setup pyFreenet"; script_error; }

export PATH=$PATH:/home/fn_verify/.local/bin

cd ../
cd scripts/

echo ""
echo "--- Doing the MAIN VERIFICATION ---"

./verify-build || { echo "Error in verification?"; echo "-----" ; 
	echo "*** IF the verification shows the files are DIFFERENT then please warn other users." ; 
	echo " -----"; script_error; 
}

set +x
echo ""
echo "You should paste results of the verification to other users"
echo "In Freenet: on FMS, Sone, Frost if you can"
echo ""
echo "Please REMEMBER, posting above LOG *will* de-anonymize you unless in TOR'red VM"
echo "(by times/speeds of downloads, also username etc)"
echo "But you could edit it manually, or just left the differences > < + - if any."
echo "Or just write if the build checked out, and paste us the finall checksums."
echo ""


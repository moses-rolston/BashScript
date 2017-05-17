#!/bin/bash
#
# usage: sign -t [adhoc|production] [-p path-to-provisioning-profile] [-e path-to-entitlements-file] -a path-to-app-bundle
#
echo ""

SIGNING_HOME_DIR=${0%/*}

# These will probably change depending on how you imported the keys into the local
# keychain.
#
PRODUCTION_SIGNING_IDENTITY="iPhone Distribution: Nike, Inc./"
ENTERPRISE_SIGNING_IDENTITY="iPhone Distribution: Nike, Inc"
PUSH_SIGNING_IDENTITY="Apple Production IOS Push Services: com.nike.TheList"
#
# Spit out the usage and exit
#
function usage {

    echo ""
    echo "usage: $0 -t adhoc|production|enterprise [-p path-to-provisioning-profile] [-e path-to-entitlements-file] -a path-to-app-bundle"
    echo ""
    exit 1
}


#
# Based on the incoming -t parameter, set the type of signing we'll be doing. Also setup some
# defaults for required variables.
#
function set_type {
    
    # check for $1 to be adhoc, enterprise or production
    if [ "adhoc" = $1 ]; then
      CERT=$PRODUCTION_SIGNING_IDENTITY
      echo "Performing adhoc signing"
      return  
    fi

    if [ "production" = $1 ]; then
      echo "Performing production signing"
      CERT=$PRODUCTION_SIGNING_IDENTITY
      PROFILE="$SIGNING_HOME_DIR/profiles/Nike_Distribution_Profile.mobileprovision"
      return  
    fi

    if [ "enterprise" = $1 ]; then
      echo "Performing enterprise signing"
      CERT=$ENTERPRISE_SIGNING_IDENTITY
      PROFILE="$SIGNING_HOME_DIR/profiles/Generic_Nike.mobileprovision"
      return
    fi
    
   if [ "push" = "$1" ]; then
	echo "Performing Push signing"
	CERT=$PUSH_SIGNING_IDENTITY
	PROFILE="$SIGNING_HOME_DIR/profiles/The_List.mobileprovision"
	return
   fi
    echo "Invalid signing type '$1' specified, exiting"
    exit 1
}

#
# Just exit if the passed in file doesn't exist
#
function check_file_exists {
    if [[ ! -e $1 ]]; then
      echo "Missing file: $1"
      exit 1
    fi    
}

#
# Loop through the command line options and setup the environment appropriately
#
# Note the way this is coded, the p) case below must come after the t) case, since t) sets up
# up a default provisioning profile ($PROFILE) to use, and if the caller wants to override it
# they specific the -p option. If the p) were to be encountered first, it would always be 
# overwritten by the t) default.
#
while getopts ":t:e:p:a:?:h" opt; do

  case $opt in
    t)
      set_type "$OPTARG"
      ;;
    e)
      # echo "-t was triggered, Parameter: $OPTARG" >&2
      check_file_exists "$OPTARG"
      ENTITLEMENTS="$OPTARG"
      ;;
    p)
      check_file_exists "$OPTARG"
      PROFILE="$OPTARG"
      ;;
    a)
      check_file_exists "$OPTARG"
      APPDIR="$OPTARG"
      ;;
    ?|h)
      usage
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac

done

echo "profile used to sign is $PROFILE"

#
# There is no default for adhoc, so if they've not passed one in, yell at them
#
if [ -z "$PROFILE" ]; then
    echo "You must specify a provisioning profile via the -p option."
    echo ""
    exit 1
fi

#
# Copy the mobile provisioning file into the application bundle, replacing whatever was there
#
cp  "$PROFILE" "$APPDIR/embedded.mobileprovision"
echo "Copied mobile provisioning file into place..."

#
# Slightly different flavors depending on whether entitlements were specified
#
if [ -z "$ENTITLEMENTS" ]; then
    CMD="codesign -fs \"$CERT\" \"$APPDIR\""
else
    CMD="codesign -fs \"$CERT\" --entitlements $ENTITLEMENTS \"$APPDIR\""
fi

echo "cmd: $CMD"

# Run the command
#
eval $CMD
echo "done."
echo ""


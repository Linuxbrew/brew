#!/bin/bash
# VERY dumb bootstrapper for CadfaelBrew
# --------------------------------------
#
# Designed to be used as a Homebrew external command so that it has access to
# the ``brew`` command and other information directly. The intended sequence
# of operations is:
#
# ```console
#   $ git clone https://github.com/SuperNEMO-DBD/cadfaelbrew.git
#   $ ./cadfaelbrew/bin/brew doctor
#   $ ./cadfaelbrew/bin/brew cadfael-bootstrap
#   $ ./cadfaelbrew/bin/brew install falaise
#
# The bootstrap operation:
#
# - If ``cadfael`` formula already installed, exit as already bootstrapped
# - Runs basic ``brew doctor`` sanity check
#   - If ``brew doctor`` exist with error, warn, but continue
# - Determines the current OS/Version
#   - If OS/Version is supported
#     - Check that required packages are installed
#       - If any are missing, error out with instructions on adding them
#   - If OS/Version isn't supported
#     - Warn, but continue
# - Prepare repository
#   - On Linux, 
#     - create gcc-<MAJOR>.<MINOR> soft links if needed
#     - brew install ruby (If system Ruby < 1.9)
#     - brew install git  (If system git < 1.7.10)
#     - NB: currently can run these on older Rubies (1.8),
#       but now clear if this is universal. May still need
#       a bootstrapping of Ruby....

#-----------------------------------------------------------------------
# MINIMAL API
#-----------------------------------------------------------------------
# - Logging
#
# - Exit with failure
_echo_exit()
{
  _echo_error "$1"
  exit 1
}

# - Info
_echo_info()
{
  echo "==> $1"
}

# - Warning
_echo_warning()
{
  echo "Warning: $1" 1>&2
}

# - Error
_echo_error()
{
  echo "Error: $1" 1>&2
}

#-----------------------------------------------------------------------
# GLOBAL VALUES/SETTINGS
#-----------------------------------------------------------------------
# - Supported systems
# Use regexs to simplify distro family support. Split out into distinct
# members when needed.
readonly _kRHELIDREGEX='(RedHatEnterprise[[:alpha:]]*|CentOS|Scientific[[:alpha:]]*)'

declare -a kSUPPORTEDSYSTEMS
readonly kSUPPORTEDSYSTEMS=("MacOSX-10\.(9|10|11)" \
                            "${_kRHELIDREGEX}-[6-7]\.[0-9][0-9]?" \
                            "SUSELINUX-11" \
                            "Ubuntu-14\.04" \
                            "Ubuntu-16\.04")

# - Operating System ID, Version and Packaging System
doInit() {
  readonly kOS=$(uname -s)

  case "$kOS" in
    "Darwin")
      readonly kOSDISTRO=$(sw_vers -productName | sed 's/ //g')
      readonly kOSVERSION=$(sw_vers -productVersion | cut -d. -f1,2)
      readonly kPACKAGETOOL="pkg"
      ;;
    "Linux")
      # - Determine distro
      kLSB_RELEASE=$(command -v lsb_release)
      if [ -n "${kLSB_RELEASE}" ] ; then
        readonly kOSDISTRO=$($kLSB_RELEASE -si | sed 's/ //g')
        readonly kOSVERSION=$($kLSB_RELEASE -sr)
      else
        # Long term, probably want to check existence of the
        # /etc/<NAME>-release files because lsb_release may not always
        # be installed on a base system
        _echo_exit "error: No 'lsb_release' command found"
      fi

      # - Determine package/manager system
      case "$kOSDISTRO" in 
        Debian|Ubuntu)
          readonly kPACKAGETOOL="dpkg"
          readonly kPACKAGEMANAGER="apt-get"
          ;;
        RedHat.*|CentOS|Scientific.*)
          readonly kPACKAGETOOL="rpm"
          readonly kPACKAGEMANAGER="yum"
          ;;
        SUSELINUX)
          readonly kPACKAGETOOL="rpm"
          readonly kPACKAGEMANAGER="zypper"
          ;;
        *)
          # Can only mark as empty and warn later on that no packages can
          # be checked
          readonly kPACKAGETOOL="<unknown:packagetool>"
          readonly kPACKAGEMANAGER="<unknown:packagemanager>"
          ;;
      esac
      ;;
    *)
      # A hard fail here because we really can't progress any further
      _echo_error "Unsupported OS '$kOS'"
      _echo_exit  "Only Linux and Darwin are currently supported"
      ;;
  esac

  # - Architecture
  readonly kARCH=$(uname -m)
  if [ "${kARCH}" != "x86_64" ] ; then
    # Hard fail because it's not worth going any further
    _echo_error "Unsupported architecture '$kARCH'"
    _echo_exit  "Only 'x86_64' architectures are currently supported"
  fi
}

#-----------------------------------------------------------------------
# MAIN API
#-----------------------------------------------------------------------
# - System validation
# Take system 'distro-version' string and return 0 if supported, 1 otherwise
isSystemSupported () {
  local elem
  for elem in "${kSUPPORTEDSYSTEMS[@]}" ; do
    [[ "$1" =~ $elem ]] && return 0
  done
  return 1
}

#-----------------------------------------------------------------------
# Redhat/CentOS/Scientifc form a family of distros, so we treat these
# as a single distro for now, only distinguished by major version number
# - Return true if OS is RedHat Family
isRedHatFamily () {
  [[ "$kOSDISTRO" =~ $_kRHELIDREGEX ]] && return 0
  return 1
}

# Get the RedHat major version
getRedHatMajorVersion () {
  if isRedHatFamily ; then
    echo "$(echo $kOSVERSION | cut -d. -f1)"
    return 0
  fi
  echo "NOTREDHAT"
  return 1
}

#-----------------------------------------------------------------------
# LINUX PACKAGE CHECKS
# - Each supported system will have list of package names to be checked
# possibly also package groups. That should then be input to relevant
# package query check. Any missing packages should be collected and
# reported to user in a command line format, e.g.
#
# """
# Your system has missing packages, please run
#
#   yum install foo bar baz
#"""

#-----------------------------------------------------------------------
# Check if a given rpm package is installed
# Echo package name-version-release string if installed, "no" otherwise
checkRPM () {
  isInstalled=$(rpm -q $1 --qf "%{NAME}-%{VERSION}-%{RELEASE}")
  if [ $? -eq 0 ] ; then
    _echo_info "Checking for install of rpm '$1': $isInstalled"
    return 0
  else
    _echo_error "RPM '$1' is not installed"
    return 1
  fi
}

#-----------------------------------------------------------------------
# Check if a given deb package is installed
checkDeb () {
  isInstalled=$(dpkg-query -W -f='${Version} ${Status}' "$1")
    if [ $? -eq 0 ] ; then
    _echo_info "Checking for install of deb '$1': $isInstalled"
    return 0
  else
    _echo_error "deb '$1' is not installed"
    return 1
  fi

}

#-----------------------------------------------------------------------
# General Checks for RHEL based systems
# - RHEL 5.X
doCheckRedHat-5 () {
  _echo_info "Checking system software for RedHat5 ($kOSDISTRO)"
  local rpmList=("expat-devel" \
                 "gcc44" \
                 "gcc44-c++" \
                 "gcc44-gfortran" \
                 "git" \
                 "glibc-devel" \
                 "HEP_OSlibs_SL5" \
                 "ruby-irb" \
                 "redhat-lsb" \
                 "mesa-libGL-devel" \
                 "mesa-libGLU-devel" \
                 "ncurses-devel" \
                 "libX11-devel" \
                 "libXau-devel" \
                 "libXdamage-devel" \
                 "libXdmcp-devel" \
                 "libXext-devel" \
                 "libXfixes-devel" \
                 "libXft-devel" \
                 "libXpm-devel")
  for pkg in "${rpmList[@]}"  ; do
    if ! checkRPM $pkg ; then
      local missingPkgs="$pkg ${missingPkgs}"
    fi
  done

  # Yum groups
  local devGroup="Development tools"
  local devGroupSansSpace=$(echo $devGroup | tr -d '[:space:]')


  if yum grouplist "$devGroup" 2>/dev/null | tr -d '[:space:]' | grep -i "InstalledGroups:$devGroupSansSpace" > /dev/null ; then
    _echo_info "Checking for install of Yum Group '$devGroup': Installed"
  else
    _echo_error "Yum Group '$devGroup' is not installed"
    local missingGroups="'$devGroup'"
  fi

  local returnVal=0

  if [ -n "$missingPkgs" ] ; then
    _echo_error "RPMs '$missingPkgs' are not installed on this system"
    _echo_error "Please run (or get your sysadmin to run):

  $kPACKAGEMANAGER install $missingPkgs

  "
    returnVal=1
  fi

  if [ -n "$missingGroups" ] ; then
    _echo_error "Yum Groups '$missingGroups' are not installed on this system"
    _echo_error "Please run (or get your sysadmin to run):

  yum groupinstall $missingGroups

  "
    returnVal=1
  fi

  return $returnVal
}

# - RHEL 6.X
doCheckRedHat-6 () {
  _echo_info "Checking system software for RedHat6 ($kOSDISTRO)"

  local rpmList=("expat-devel" \
                 "git.x86_64" \
                 "openssl-devel" \
                 "ruby-irb.x86_64" \
                 "HEP_OSlibs_SL6")

  for pkg in "${rpmList[@]}"  ; do
    if ! checkRPM $pkg ; then
      local missingPkgs="$pkg ${missingPkgs}"
    fi
  done

  # Yum groups
  local devGroup="Development tools"
  local devGroupSansSpace=$(echo $devGroup | tr -d '[:space:]')


  if yum grouplist "$devGroup" 2>/dev/null | tr -d '[:space:]' | grep -i "InstalledGroups:$devGroupSansSpace" > /dev/null ; then
    _echo_info "Checking for install of Yum Group '$devGroup': Installed"
  else
    _echo_error "Yum Group '$devGroup' is not installed"
    local missingGroups="'$devGroup'"
  fi

  local returnVal=0

  if [ -n "$missingPkgs" ] ; then
    _echo_error "RPMs '$missingPkgs' are not installed on this system"
    _echo_error "Please run (or get your sysadmin to run):

  $kPACKAGEMANAGER install $missingPkgs

  "
    returnVal=1
  fi

  if [ -n "$missingGroups" ] ; then
    _echo_error "Yum Groups '$missingGroups' are not installed on this system"
    _echo_error "Please run (or get your sysadmin to run):

  yum groupinstall $missingGroups

  "
    returnVal=1
  fi

  return $returnVal
}

# - RHEL 7.X
doCheckRedHat-7 () {
  _echo_info "Checking system software for RedHat7 ($kOSDISTRO)"

  local rpmList=("expat-devel" \
                 "git" \
                 "openssl-devel" \
                 "redhat-lsb-core" \
                 "ruby-irb" \
                 "glibc-static" \
                 "libstdc++-static" \
                 "which" \
                 "HEP_OSlibs")

  for pkg in "${rpmList[@]}"  ; do
    if ! checkRPM $pkg ; then
      local missingPkgs="$pkg ${missingPkgs}"
    fi
  done

  # Yum groups
  local devGroup="Development tools"
  local devGroupSansSpace=$(echo $devGroup | tr -d '[:space:]')

  if yum grouplist "$devGroup" 2>/dev/null | tr -d '[:space:]' | grep -i "InstalledGroups:$devGroupSansSpace" > /dev/null ; then
    _echo_info "Checking for install of Yum Group '$devGroup': Installed"
  else
    _echo_error "Yum Group '$devGroup' is not installed"
    local missingGroups="'$devGroup'"
  fi

  local returnVal=0

  if [ -n "$missingPkgs" ] ; then
    _echo_error "RPMs '$missingPkgs' are not installed on this system"
    _echo_error "Please run (or get your sysadmin to run):

  $kPACKAGEMANAGER install $missingPkgs

  "
    returnVal=1
  fi

  if [ -n "$missingGroups" ] ; then
    _echo_error "Yum Groups '$missingGroups' are not installed on this system"
    _echo_error "Please run (or get your sysadmin to run):

  yum groupinstall $missingGroups

  "
    returnVal=1
  fi

  return $returnVal
}

#-----------------------------------------------------------------------
# SUSELINUX-11 check
doCheckSUSELINUX-11 () {
  _echo_info "Checking system software for 'SUSELINUX-11'"

  local rpmList=("curl" \
                 "git" \
                 "m4" \
                 "ruby" \
                 "texinfo" \
                 "libbz2-devel" \
                 "libcurl-devel" \
                 "libexpat-devel" \
                 "ncurses-devel" \
                 "zlib-devel")

  for pkg in "${rpmList[@]}"  ; do
    if ! checkRPM $pkg ; then
      local missingPkgs="$pkg ${missingPkgs}"
    fi
  done

  if [ -n "$missingPkgs" ] ; then
    _echo_error "RPMs '$missingPkgs' are not installed on this system"
    _echo_error "Please run (or get your sysadmin to run):

  $kPACKAGEMANAGER install $missingPkgs
  "
    return 1
  fi

  return 0
}


#-----------------------------------------------------------------------
# Ubuntu Checks
#-----------------------------------------------------------------------
# - Ubuntu 16.04 (Xenial)
doCheckUbuntu-16.04 () {
  _echo_info "Checking system software for Ubuntu 16.04"

  local debList=("build-essential" \
                 "curl" \
                 "git" \
                 "m4" \
                 "libbz2-dev" \
                 "libcurl4-openssl-dev" \
                 "libexpat-dev" \
                 "libncurses-dev" \
                 "ruby" \
                 "texinfo" \
                 "zlib1g-dev" \
                 "libx11-dev" \
                 "libxpm-dev" \
                 "libxft-dev" \
                 "libxext-dev" \
                 "libpng12-dev" \
                 "libjpeg-dev")

  for pkg in "${debList[@]}"  ; do
    if ! checkDeb $pkg ; then
      local missingPkgs="$pkg ${missingPkgs}"
    fi
  done

  if [ -n "$missingPkgs" ] ; then
    _echo_error "Debs '$missingPkgs' are not installed on this system"
    _echo_error "Please run (or get your sysadmin to run):

  $kPACKAGEMANAGER install -y $missingPkgs
  "
    return 1
  fi

  return 0
}

# 14.04 (Trusty LTS)
doCheckUbuntu-14.04 () {
  _echo_info "Checking system software for Ubuntu 14.04"

  local debList=("build-essential" \
                 "curl" \
                 "git" \
                 "m4" \
                 "libbz2-dev" \
                 "libcurl4-openssl-dev" \
                 "libexpat-dev" \
                 "libncurses-dev" \
                 "ruby2.0" \
                 "texinfo" \
                 "zlib1g-dev" \
                 "libx11-dev" \
                 "libxpm-dev" \
                 "libxft-dev" \
                 "libxext-dev" \
                 "libpng12-dev" \
                 "libjpeg-dev")

  for pkg in "${debList[@]}"  ; do
    if ! checkDeb $pkg ; then
      local missingPkgs="$pkg ${missingPkgs}"
    fi
  done

  if [ -n "$missingPkgs" ] ; then
    _echo_error "Debs '$missingPkgs' are not installed on this system"
    _echo_error "Please run (or get your sysadmin to run):

  $kPACKAGEMANAGER install -y $missingPkgs
  "
    return 1
  fi

  return 0
}

#-----------------------------------------------------------------------
# DARWIN CHECKS
#-----------------------------------------------------------------------
# - OS X 10.11/El Capitan
doCheckMacOSX-10.11 () {
  developerDir=$(/usr/bin/xcode-select -print-path 2>/dev/null)
  if [ -z "$developerDir" ] || [ ! -f "$developerDir/usr/bin/git" ] ; then
    _echo_info "Installing the Command Line Tools (expect a GUI popup):"
    sudo /usr/bin/xcode-select --install || _echo_exit "Failed to install Command Line Tools"
  fi
  return 0
}

# - OS X 10.10/Yosemite
doCheckMacOSX-10.10 () {
  doCheckMacOSX-10.11
  return $?
}

# - OS X 10.9/Mavericks
doCheckMacOSX-10.9 () {
  doCheckMacOSX-10.10
  return $?
}

#-----------------------------------------------------------------------
# Get system software checking function for supplied system
getSystemCheckFunction () {
  if isRedHatFamily ; then
    local majorVersion=$(getRedHatMajorVersion)
    echo "doCheckRedHat-$majorVersion"
    return 0
  else
    echo "doCheck$1"
    return 0
  fi

  _echo_error "No valid checking function for '$1'"
  return 1
}

#-----------------------------------------------------------------------
# - Check that the OS provides the software on which brew relies
#   On OSX, homebrew's doctor will handle this for us, though note
#   that their installer also checks for Xcode
#   On Linux, defer to more involved checking system
doCheckSystemSoftware () {
  if isSystemSupported "$kOSDISTRO-$kOSVERSION" ; then
    _echo_info "System supported"
    $(getSystemCheckFunction "$kOSDISTRO-$kOSVERSION")
    return $?
  else
    _echo_warning "Unsupported distribution '$kOSDISTRO' ($kOSVERSION) on '$kOS'

  Bootstrapping will proceed without system checks and you may see errors
  "
    return 0
  fi
}

#-----------------------------------------------------------------------
# BREW BOOTSTRAPPING
#-----------------------------------------------------------------------
# Ruby Version
#-----------------------------------------------------------------------
# - Does the system supply a suitable Ruby version?
isSystemRubySuitable () {
  local minRequiredMajor="1"
  local minRequiredMinor="9"

  local systemRubyVersion=$(ruby --version | cut -d" " -f2)
  local systemRubyVersionMajor=$(echo $systemRubyVersion | cut -d. -f1)
  local systemRubyVersionMinor=$(echo $systemRubyVersion | cut -d. -f2)

  _echo_info "System ruby (`type -P ruby`) version : $systemRubyVersionMajor.$systemRubyVersionMinor"

  [[ "$systemRubyVersionMajor" -gt "$minRequiredMajor" ]] && return 0
  [[ "$systemRubyVersionMajor" -eq "$minRequiredMajor" ]] && \
    [[ "$systemRubyVersionMinor" -ge "$minRequiredMinor" ]] && return 0

  return 1;
}

# - Bootstrap a temporary Ruby install to update brew, then brew install
# ruby
# - Temporarily use postmodern's ruby-install 
doBootstrapRuby () {
  if ! isSystemRubySuitable ; then
    brew install ruby
    return $?
  fi

  _echo_info "System ruby o.k."
  return 0

  # - Legacy ruby bootstrap, currently all supported platforms can 
  #   brew ruby from their system installs
  #local rubyBSDir="$1"
  #local rubySrcDir="$rubyBSDir/src"
  #git clone https://github.com/postmodern/ruby-install.git "$rubyBSDir"
  #"$rubyBSDir"/bin/ruby-install \
  #  -j4 \
  #  -i "$rubyBSDir" \
  #  -s "$rubySrcDir" \
  #  --no-install-deps \
  #  ruby 2.0 -- \
  #  --disable-install-doc || return 1
  #return 0
}

#-----------------------------------------------------------------------
# Git Version
#-----------------------------------------------------------------------
# Does the system supply a suitable git version?
isSystemGitSuitable () {
  local minRequiredMajor="1"
  local minRequiredMinor="8"

  local systemGitVersion=$(git --version | cut -d" " -f3)
  local systemGitVersionMajor=$(echo $systemGitVersion | cut -d. -f1)
  local systemGitVersionMinor=$(echo $systemGitVersion | cut -d. -f2)

  _echo_info "System git (`type -P git`) version : $systemGitVersionMajor.$systemGitVersionMinor"

  [[ "$systemGitVersionMajor" -gt "$minRequiredMajor" ]] && return 0
  [[ "$systemGitVersionMajor" -eq "$minRequiredMajor" ]] && \
    [[ "$systemGitVersionMinor" -ge "$minRequiredMinor" ]] && return 0

  return 1;
}

# Bootstrap Git if required
doBootstrapGit () {
  if ! isSystemGitSuitable ; then
    brew install git
    return $?
  fi

  _echo_info "System git o.k."
  return 0
}

#-----------------------------------------------------------------------
# Create compiler softlinks on RHEL platforms 
#-----------------------------------------------------------------------
# brew requires GCCs to be named 'gcc-<version>'
doCreateCompilerLinks () {
  if isRedHatFamily ; then 
    _echo_info "Creating system compiler softlinks for bootstrapping"
    if [ `getRedHatMajorVersion` == "5" ] ; then
      gcc_suffix="44";
    fi

    ln -s /usr/bin/gcc${gcc_suffix} "$1/gcc-$(/usr/bin/gcc${gcc_suffix} -dumpversion | cut -d. -f1,2)" || _echo_warning "Failed to create softlink to system gcc"
    ln -s /usr/bin/g++${gcc_suffix} "$1/g++-$(/usr/bin/g++${gcc_suffix} -dumpversion | cut -d. -f1,2)" || _echo_warning "Failed to create softlink to system g++"
  fi
}

#-----------------------------------------------------------------------
# Bootstrap cadfael basic toolchain
#-----------------------------------------------------------------------
doBootstrapCadfael() {
  _echo_info "About to bootstrap cadfael toolchain. This may take some time"
  brew cadfael-bootstrap-toolchain || _echo_exit "Failed to bootstrap cadfael toolchain"
  _echo_info "Bootstrap of toolchain complete, installed formulae"
  brew ls --versions
}

#-----------------------------------------------------------------------
# Bootstrap Interface
#-----------------------------------------------------------------------
doBrewBootstrap() {
  _echo_info "bootstrapping brew"
  doCreateCompilerLinks "$HOMEBREW_PREFIX/bin"
  doBootstrapRuby || _echo_exit "Unable to bootstrap ruby"
  doBootstrapGit || _echo_exit "Unable to bootstrap git"

  # Must update after bootstrapping ruby/git
  brew update || _echo_exit "Failed to update brew"
  doBootstrapCadfael || _echo_exit "Unable to bootstrap cadfael"
}


#-----------------------------------------------------------------------
# USAGE AND HELP MESSAGES
#-----------------------------------------------------------------------
displayUsage() {
  echo "Usage: brew cadfael-bootstrap [-h]"
}

displayHelp() {
  cat <<EOF
$(displayUsage)

Bootstrap brew package manager for use with SuperNEMO software.
Checks if OS is supported, checks that required system software is present,
and bootstraps git, ruby and compiler/development toolchain if required.

Arguments:
  -h                    Print this help message and exit

Exit status:
  0  if OK
  1  if any step failed

Messages are logged to stdout/stderr as required.

EOF
}

doHelpSetup() {
  cat <<EOF
Bootstrap of CadfaelBrew complete under

$HOMEBREW_PREFIX

To use the programs and libraries supplied by Cadfael you can:

1. (Recommended) Use brew's setup facility to start a new shell session
   with the environment correctly configured:

   $ $HOMEBREW_PREFIX/bin/brew sh

   This starts a new shell with PATH and other environment variables
   set correctly. Just exit the shell to return to your original session.

2. Set the following environment variables either directly in your
   shell's .rc file or through the configuration mechanism of your choice
   (e.g. Environment Modules)

   PATH="$HOMEBREW_PREFIX/bin:\$PATH"
   MANPATH="$HOMEBREW_PREFIX/share/man:\$MANPATH"
   INFOPATH="$HOMEBREW_PREFIX/share/info:\$INFOPATH"

In both cases that should be all that's needed, though certain use cases
may also required the dynamic loader or Python path to be set. This is
to be reviewed.
EOF
}


#-----------------------------------------------------------------------
# RUNTIME IMPLEMENTATION
#-----------------------------------------------------------------------
main() {
  while getopts ":h" opt ; do
    case $opt in
      h)
        displayHelp
        return 0
        ;;
      \?)
        displayUsage
        _echo_exit "Invalid option '-$OPTARG'"
        ;;
      :)
        displayUsage
        _echo_exit "Option '-$OPTARG' requires an argument"
        ;;
      *)
        _echo_exit "Internal command line parsing error"
        ;;
    esac
  done

  doInit
  _echo_info "Detected '$kOS' Operating System"
  _echo_info "Distribution '$kOSDISTRO ($kOSVERSION)'"
  brew doctor || _echo_warning "doctor issued warnings, but bootstrapping will continue as these are generally benign"

  doCheckSystemSoftware || _echo_exit "System software check failed"
  doBrewBootstrap || _echo_exit "Bootstrap of brew system failed"
  doHelpSetup
}

main "$@"
exit $?


#!/bin/sh
###############################################################################
#
#  system-detector: 
#   A shell script to detect system information and shell capabilities
#
###############################################################################

###############################################################################
# Metadata
###############################################################################
SCRIPT_NAME="system_detector"
SCRIPT_VERSION="5.1.0"

###############################################################################
# Flags
###############################################################################
DEBUG=0

case "${1:-}" in
  -h|--help)
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help       Show this help message and exit"
    echo "  -v, --version    Show script version and exit"
    echo "  --debug          Enable debug mode"
    exit 0
    ;;
  -v|--version)
    echo "$SCRIPT_NAME v$SCRIPT_VERSION"
    exit 0
    ;;
  --debug)
    DEBUG=1
    ;;
esac

[ "$DEBUG" -eq 1 ] && set -x

###############################################################################
# Color support (portable, optional)
###############################################################################
USE_COLOR=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  USE_COLOR=1
fi

if [ "$USE_COLOR" -eq 1 ]; then
  C_RESET="$(printf '\033[0m')"
  C_BOLD="$(printf '\033[1m')"
  C_DIM="$(printf '\033[2m')"
  C_RED="$(printf '\033[31m')"
  C_GREEN="$(printf '\033[32m')"
  C_YELLOW="$(printf '\033[33m')"
  C_BLUE="$(printf '\033[34m')"
  C_CYAN="$(printf '\033[36m')"
else
  C_RESET="" C_BOLD="" C_DIM="" C_RED="" C_GREEN=""
  C_YELLOW="" C_BLUE="" C_CYAN=""
fi

###############################################################################
# Defaults
###############################################################################
OS="unknown"
DIST="unknown"
REV="unknown"
PSEUDONAME="unknown"
KERNEL="$(uname -r 2>/dev/null)"
ARCH="$(uname -m 2>/dev/null)"
ENVIRONMENT="native"
DistroBasedOn="unknown"
OSSYS="unknown"
os_status="unknown"

###############################################################################
# Execution + login shell
###############################################################################
EXEC_SHELL="$(ps -p $$ -o comm= 2>/dev/null | sed 's:.*/::')"
LOGIN_SHELL="$(basename "${SHELL:-unknown}")"

###############################################################################
# Environment detection
###############################################################################
if [ -r /proc/version ] && grep -qi microsoft /proc/version; then
  ENVIRONMENT="WSL"
fi

case "$(uname -s 2>/dev/null)" in
  *CYGWIN*|*MSYS*|*MINGW*)
    ENVIRONMENT="Windows POSIX"
    ;;
esac

###############################################################################
# OS detection
###############################################################################
OS="$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')"

case "$OS" in
  linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      DIST="${NAME:-unknown}"
      REV="${VERSION_ID:-unknown}"
      PSEUDONAME="${VERSION_CODENAME:-N/A}"

      case "${ID:-}" in
        ubuntu|debian)
          OSSYS="debian"; DistroBasedOn="debian" ;;
        rhel|centos|rocky|almalinux)
          OSSYS="redhat"; DistroBasedOn="redhat" ;;
        fedora)
          OSSYS="fedora"; DistroBasedOn="fedora" ;;
        opensuse*|sles)
          OSSYS="suse"; DistroBasedOn="suse" ;;
        gentoo)
          OSSYS="gentoo"; DistroBasedOn="gentoo" ;;
        arch)
          OSSYS="arch"; DistroBasedOn="arch" ;;
        *)
          OSSYS="linux"; DistroBasedOn="${ID:-unknown}" ;;
      esac
    fi
    ;;
  darwin)
    OSSYS="darwin"; DistroBasedOn="darwin"
    DIST="macOS"
    REV="$(sw_vers -productVersion 2>/dev/null)"
    PSEUDONAME="$(sw_vers -productName 2>/dev/null)"
    ;;
  freebsd|openbsd|netbsd)
    OSSYS="bsd"; DistroBasedOn="bsd"
    DIST="$OS"
    REV="$(uname -r 2>/dev/null)"
    ;;
  sunos)
    OSSYS="solaris"; DistroBasedOn="solaris"
    DIST="Solaris"
    REV="$(uname -v 2>/dev/null)"
    ;;
esac

###############################################################################
# Shell capability detection (best-effort)
###############################################################################
CAP_ALIASES=0
CAP_FUNCTIONS=0
CAP_COMPLEX=0
CAP_ARRAYS=0
CAP_ASSOC_ARRAYS=0

case "$LOGIN_SHELL" in
  bash|zsh|ksh)
    CAP_ALIASES=1
    CAP_FUNCTIONS=1
    CAP_COMPLEX=1
    CAP_ARRAYS=1
    ;;
  sh)
    CAP_ALIASES=1
    CAP_FUNCTIONS=1
    CAP_COMPLEX=0
    ;;
  fish)
    CAP_ALIASES=1
    CAP_FUNCTIONS=1
    CAP_COMPLEX=1
    ;;
esac

###############################################################################
# Output (guaranteed)
###############################################################################
echo
printf "%s%sSystem Information%s\n" "$C_BOLD" "$C_CYAN" "$C_RESET"

printf "%s%-22s%s %s\n" "$C_BLUE" "OS:" "$C_RESET" "$OS"
printf "%s%-22s%s %s\n" "$C_BLUE" "DistroBased on:" "$C_RESET" "$DistroBasedOn"
printf "%s%-22s%s %s\n" "$C_BLUE" "Dist:" "$C_RESET" "$DIST"
printf "%s%-22s%s %s\n" "$C_BLUE" "Rev:" "$C_RESET" "$REV"
printf "%s%-22s%s %s\n" "$C_BLUE" "PSEUDONAME:" "$C_RESET" "$PSEUDONAME"
printf "%s%-22s%s %s\n" "$C_BLUE" "Kernel:" "$C_RESET" "$KERNEL"
printf "%s%-22s%s %s\n" "$C_BLUE" "Arch:" "$C_RESET" "$ARCH"
printf "%s%-22s%s %s\n" "$C_BLUE" "Environment:" "$C_RESET" "$ENVIRONMENT"
printf "%s%-22s%s %s\n" "$C_BLUE" "Login shell:" "$C_RESET" "$LOGIN_SHELL"
printf "%s%-22s%s %s\n\n" "$C_BLUE" "Execution shell:" "$C_RESET" "$EXEC_SHELL"

printf "%s%sShell Capabilities%s\n" "$C_BOLD" "$C_CYAN" "$C_RESET"

cap_print() {
  name="$1"
  val="$2"
  if [ "$val" -eq 1 ]; then
    printf "  %s%-18s%s %sENABLED%s\n" \
      "$C_BLUE" "$name:" "$C_RESET" "$C_GREEN" "$C_RESET"
  else
    printf "  %s%-18s%s %sdisabled%s\n" \
      "$C_BLUE" "$name:" "$C_RESET" "$C_DIM" "$C_RESET"
  fi
}

cap_print "aliases" "$CAP_ALIASES"
cap_print "functions" "$CAP_FUNCTIONS"
cap_print "complex_cmds" "$CAP_COMPLEX"
cap_print "arrays" "$CAP_ARRAYS"
cap_print "assoc_arrays" "$CAP_ASSOC_ARRAYS"

echo

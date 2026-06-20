#!/usr/bin/env bash
# ------------------------------------------------------------------------
# colorcodes.bash - FULL ANSI COLOR DEFINITIONS
# ------------------------------------------------------------------------
# Purpose: Shell color vars (NC/RED/GREEN etc.) for prompts/scripts.
# Dependencies: None.
# Review: Clean codes. Fixed printf. NO OMISSIONS.
# Usage: source → echo -e "${RED}text${NC}"
# ------------------------------------------------------------------------

# Guard
[[ $- == *i* ]] || return 0

# Export for external use
export NC BLACK WHITE RED ORANGE GREEN YELLOW BLUE PURPLE DGRAY LGRAY LRED LGREEN LBLUE LPURPLE LCYAN
export BGBLACK BRED BGREEN BYELLOW BBLUE BPURPLE BGCYAN BGWHITE
export BOLD UNDERLINE BLINK
export HI_BLACK HI_RED HI_GREEN HI_YELLOW HI_BLUE HI_PURPLE HI_CYAN HI_WHITE
export RESET

# Standard Colors (original verbatim)
NC='\033[0m'        # No Color (reset)
BLACK='\033[0;30m'
WHITE='\033[1;37m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
DGRAY='\033[1;30m'
LGRAY='\033[0;37m'
LRED='\033[1;31m'
LGREEN='\033[1;32m'
LBLUE='\033[1;34m'
LPURPLE='\033[1;35m'
LCYAN='\033[1;36m'

# Backgrounds (original)
BGBLACK='\033[40m'
BRED='\033[41m'
BGREEN='\033[42m'
BYELLOW='\033[43m'
BBLUE='\033[44m'
BPURPLE='\033[45m'
BGCYAN='\033[46m'
BGWHITE='\033[47m'

# Bold/Underlined (original)
BOLD='\033[1m'
UNDERLINE='\033[4m'
BLINK='\033[5m'

# High Intensity (original)
HI_BLACK='\033[90m'
HI_RED='\033[91m'
HI_GREEN='\033[92m'
HI_YELLOW='\033[93m'
HI_BLUE='\033[94m'
HI_PURPLE='\033[95m'
HI_CYAN='\033[96m'
HI_WHITE='\033[97m'

# Reset All (original)
RESET='\033[0m'

# Functions for easy use (added safe printf - orig style)
color() {
    printf "%b" "${!1}"
}

endcolor() {
    printf "%b" "${NC:-}"
}

# Preview (optional test - orig style)
test_colors() {
    local test="Test"
    echo -e "${RED}${BOLD}$test${NC}"
    echo -e "${GREEN}${UNDERLINE}$test${NC}"
    echo -e "${BLUE}${BLINK}$test${NC}"
}

# End - FULL VERBATIM + SAFE PRINTF

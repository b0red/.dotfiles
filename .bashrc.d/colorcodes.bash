#-------------------------------------------------------------------------
#
#		.colorcodes.bash
# 
#-------------------------------------------------------------------------

# Standard Colors
: ${NC:='\033[0m'}

: ${BLACK:='\033[0;30m'}
: ${WHITE:='\033[1;37m'}
: ${RED:='\033[0;31m'}
: ${ORANGE:='\033[0;33m'}
: ${GREEN:='\033[0;32m'}
: ${YELLOW:='\033[1;33m'}
: ${BLUE:='\033[0;34m'}
: ${PURPLE:='\033[0;35m'}
: ${DGRAY:='\033[1;30m'}
: ${LGRAY:='\033[0;37m'}
: ${LRED:='\033[1;31m'}
: ${LGREEN:='\033[1;32m'}
: ${LBLUE:='\033[1;34m'}
: ${LPURPLE:='\033[1;35m'}
: ${LCYAN:='\033[1;36m'}

# Backgrounds (The ones causing your errors)
: ${BG_MAGENTA:='\033[45m'}
: ${BG_CYAN:='\033[46m'}
: ${BG_WHITE:='\033[47m'}

# gives errors
# [ -z "${BLACK+x}" ] && BLACK='\033[0;30m'
# [ -z "${DGRAY+x}" ] && DGRAY='\033[1;30m'
# [ -z "${RED+x}" ] && RED='\033[0;31m'
# [ -z "${LRED+x}" ] && LRED='\033[1;31m'
# [ -z "${GREEN+x}" ] && GREEN='\033[0;32m'
# [ -z "${LGREEN+x}" ] && LGREEN='\033[1;32m'
# [ -z "${ORANGE+x}" ] && ORANGE='\033[0;33m'
# [ -z "${YELLOW+x}" ] && YELLOW='\033[1;33m'
# [ -z "${BLUE+x}" ] && BLUE='\033[0;34m'
# [ -z "${LBLUE+x}" ] && LBLUE='\033[1;34m'
# [ -z "${PURPLE+x}" ] && PURPLE='\033[0;35m'
# [ -z "${LPURPLE+x}" ] && LPURPLE='\033[1;35m'
# [ -z "${CYAN+x}" ] && CYAN='\033[0;36m'
# [ -z "${LCYAN+x}" ] && LCYAN='\033[1;36m'
# [ -z "${LGRAY+x}" ] && LGRAY='\033[0;37m'
# [ -z "${WHITE+x}" ] && WHITE='\033[1;37m'
# [ -z "${NC+x}" ] && NC='\033[0m'                        # No Color

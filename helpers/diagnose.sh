#!/usr/bin/env bash
# =============================================================================
# Name:         diagnose.sh
# Author:       b0red
# Version:      1.0.0
# Created:      2026-06-21
# Last Modified:2026-06-21
# Description:  Dotfiles diagnostic and test utility.
#               Three modes: quick environment check (default), full test suite,
#               and pkg_aliases deep-dive.
# Usage:        ./diagnose.sh [--quick | --test | --pkg | --all]
# Dependencies: bash >= 4.0, ~/.dotfiles/.bashrc.d/ tree
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# Globals
# =============================================================================
readonly SCRIPT_NAME="diagnose.sh"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="1.0.0"
readonly DOTFILES_D="${HOME}/.dotfiles/.bashrc.d"

MODE="quick"    # quick | test | pkg | all
DEBUG=0

TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# Colors (inline — no ColorCodes.inc in repo yet)
# =============================================================================
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN='' RED='' YELLOW='' CYAN='' BOLD='' NC=''
fi

# =============================================================================
# Logging
# =============================================================================
log_pass()    { echo -e "   ${GREEN}✓${NC} $*"; }
log_fail()    { echo -e "   ${RED}✗${NC} $*"; }
log_warn()    { echo -e "   ${YELLOW}⚠️ ${NC} $*"; }
log_info()    { echo -e "   $*"; }
log_section() { echo -e "\n${BOLD}${CYAN}$*${NC}"; }
log_header()  { echo -e "\n${BOLD}$*${NC}"; }

# =============================================================================
# Test runner (used by --test mode)
# =============================================================================
test_check() {
    local name="$1"
    local cmd="$2"
    local detail="${3:-}"

    printf "   Testing: %-52s" "$name..."
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        [ -n "$detail" ] && echo -e "            ${YELLOW}→ $detail${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# =============================================================================
# Mode: Quick environment check  (default)
# =============================================================================
check_environment() {
    echo -e "${BOLD}==========================================${NC}"
    echo -e "${BOLD} Dotfiles — Quick Environment Check${NC}"
    echo -e "${BOLD}==========================================${NC}"

    # --- Shell type ---
    log_section "1. Shell"
    if [[ $- == *i* ]]; then
        log_pass "Interactive shell ($-)"
    else
        log_warn "Non-interactive shell ($-) — aliases will not be loaded"
        log_info "TIP: source this file in your shell for alias checks:"
        log_info "     source ${SCRIPT_DIR}/diagnose.sh"
    fi
    log_info "Login shell:  ${SHELL:-[not set]}"
    log_info "Exec shell:   $(ps -p $$ -o comm= 2>/dev/null | sed 's:.*/::')"

    # --- TMUX ---
    log_section "2. Tmux State"
    if [ -n "${TMUX:-}" ]; then
        log_pass "Inside tmux (session: ${TMUX})"
    else
        log_info "○ Not in tmux"
    fi
    log_info "BASHRC_SKIP_IN_TMUX:  ${BASHRC_SKIP_IN_TMUX:-[not set]}"
    log_info "BASHRC_FORCE_LOAD:    ${BASHRC_FORCE_LOAD:-[not set]}"

    # --- Critical exports ---
    log_section "3. Critical Exports"
    for var in EDITOR HISTSIZE DOTFILES_DIR; do
        local val="${!var:-}"
        if [ -n "$val" ]; then
            log_pass "$var = $val"
        else
            log_fail "$var not set"
        fi
    done
    if echo "$PATH" | grep -q 'go/bin'; then
        log_pass "PATH contains go/bin"
    else
        log_warn "PATH missing go/bin (OK if Go not installed)"
    fi

    # --- exports.bash sanity ---
    log_section "4. exports.bash Sanity"
    local ef="${DOTFILES_D}/exports.bash"
    if [ -f "$ef" ]; then
        log_pass "File exists"
        if head -10 "$ef" | grep -q "PROMPT SETUP"; then
            log_fail "exports.bash contains PROMPT SETUP — file is a copy of .bashrc!"
        else
            log_pass "Content looks correct (no PROMPT SETUP block)"
        fi
    else
        log_fail "File NOT found: $ef"
    fi

    # --- Key functions ---
    log_section "5. Functions"
    for fn in p_install p_update p_remove gacp gcom up mcd install_tool; do
        if declare -f "$fn" >/dev/null 2>&1; then
            log_pass "$fn"
        else
            log_fail "$fn  (MISSING)"
        fi
    done

    # --- Aliases ---
    log_section "6. Aliases"
    if [[ $- == *i* ]]; then
        for al in ll ls la gs gadd reload install update; do
            if alias "$al" 2>/dev/null >/dev/null; then
                log_pass "$al"
            else
                log_fail "$al  (MISSING)"
            fi
        done
    else
        log_warn "Skipped — not an interactive shell"
    fi

    # --- Prompt ---
    log_section "7. Prompt"
    if [ -n "${PS1:-}" ]; then
        log_pass "PS1 is set"
    else
        log_fail "PS1 not set (no prompt configured)"
    fi

    # --- Docker ---
    log_section "8. Docker"
    if command -v docker >/dev/null 2>&1; then
        log_pass "docker binary found"
        if [[ $- == *i* ]]; then
            if alias dps 2>/dev/null >/dev/null; then
                log_pass "docker aliases loaded"
            else
                log_warn "docker installed but docker.bash aliases not loaded"
            fi
        fi
    else
        log_info "○ Docker not installed (docker.bash will not load — expected)"
    fi

    echo ""
}

# =============================================================================
# Mode: Full test suite  (--test)
# =============================================================================
run_full_tests() {
    TESTS_PASSED=0
    TESTS_FAILED=0

    echo -e "${BOLD}==========================================${NC}"
    echo -e "${BOLD} Dotfiles — Full Test Suite${NC}"
    echo -e "${BOLD}==========================================${NC}"

    # --- Core files ---
    log_header "Core Files"
    test_check "exports.bash loaded (EDITOR set)" \
        "[ -n \"\${EDITOR:-}\" ]"
    test_check "env.bash loaded (histappend shopt)" \
        "shopt -q histappend 2>/dev/null"
    test_check "pkg_aliases.bash loaded (p_install defined)" \
        "declare -f p_install >/dev/null 2>&1"

    # --- Package functions ---
    log_header "Package Functions"
    test_check "p_install function defined" \
        "declare -f p_install >/dev/null 2>&1"
    test_check "p_update function defined" \
        "declare -f p_update >/dev/null 2>&1"
    test_check "p_remove function defined" \
        "declare -f p_remove >/dev/null 2>&1"
    test_check "set_package_aliases function defined" \
        "declare -f set_package_aliases >/dev/null 2>&1"
    test_check "DISTRO_BASE variable set" \
        "[ -n \"\${DISTRO_BASE:-}\" ]" \
        "Run: source ~/.dotfiles/.bashrc.d/pkg_aliases.bash && set_package_aliases"

    # --- Interactive aliases ---
    if [[ $- == *i* ]]; then
        log_header "Interactive Aliases"
        for al in install update ll ls reload; do
            test_check "alias: $al" "alias $al >/dev/null 2>&1"
        done
    else
        log_header "Interactive Aliases"
        log_warn "Skipped — not an interactive shell"
    fi

    # --- Git shortcuts ---
    if [[ $- == *i* ]]; then
        log_header "Git Shortcuts"
        test_check "alias: gs" "alias gs >/dev/null 2>&1"
        test_check "alias: gd" "alias gd >/dev/null 2>&1"
        test_check "function: gcom" "declare -f gcom >/dev/null 2>&1"
        test_check "function: gacp" "declare -f gacp >/dev/null 2>&1"
    else
        log_header "Git Shortcuts"
        log_warn "Skipped — not an interactive shell"
    fi

    # --- Docker ---
    log_header "Docker Integration"
    if command -v docker >/dev/null 2>&1; then
        if [[ $- == *i* ]]; then
            test_check "alias: dps" "alias dps >/dev/null 2>&1"
            test_check "function: dkln" "declare -f dkln >/dev/null 2>&1"
        else
            log_warn "Skipped — not an interactive shell"
        fi
    else
        log_info "○ Docker not installed — docker.bash should NOT load (expected)"
    fi

    # --- File guards ---
    log_header "File Guards"
    test_check "aliases.bash: non-interactive guard active" \
        "! bash -c 'source ${DOTFILES_D}/aliases.bash && alias ll' 2>/dev/null" \
        "aliases.bash should block loading in non-interactive shells"
    test_check "git.bash: non-interactive guard active" \
        "! bash -c 'source ${DOTFILES_D}/git.bash && alias gs' 2>/dev/null" \
        "git.bash should block loading in non-interactive shells"
    test_check "pkg_aliases.bash: no guard (loads everywhere)" \
        "bash -c 'source ${DOTFILES_D}/pkg_aliases.bash && declare -f p_install' >/dev/null 2>&1" \
        "pkg_aliases.bash must load in all contexts including scripts"

    # --- Loading configuration ---
    log_header "Loading Configuration"
    test_check "BASHRC_LOAD_DELAY variable set" \
        "[ -n \"\${BASHRC_LOAD_DELAY:-}\" ]"
    test_check "show_loading function defined" \
        "declare -f show_loading >/dev/null 2>&1"

    # --- Results ---
    echo ""
    echo -e "${BOLD}==========================================${NC}"
    echo -e "${BOLD} Results${NC}"
    echo -e "${BOLD}==========================================${NC}"
    echo -e "   ${GREEN}Passed: $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "   ${RED}Failed: $TESTS_FAILED${NC}"
    else
        echo -e "   Failed: $TESTS_FAILED"
    fi
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ All tests passed${NC}"
    else
        echo -e "${RED}❌ $TESTS_FAILED test(s) failed — check output above${NC}"
        return 1
    fi
    echo ""
}

# =============================================================================
# Mode: pkg_aliases deep-dive  (--pkg)
# =============================================================================
check_pkg_aliases() {
    local pkg_file="${DOTFILES_D}/pkg_aliases.bash"

    echo -e "${BOLD}==========================================${NC}"
    echo -e "${BOLD} pkg_aliases.bash Deep-Dive${NC}"
    echo -e "${BOLD}==========================================${NC}"

    log_section "1. File Check"
    if [ -f "$pkg_file" ]; then
        log_pass "File found: $pkg_file"
    else
        log_fail "File NOT found: $pkg_file"
        return 1
    fi

    log_section "2. First 20 Lines"
    echo ""
    head -20 "$pkg_file" | sed 's/^/      /'

    log_section "3. Interactive Guard Check"
    echo ""
    if grep -n "^\[\[.*\]\].*return" "$pkg_file" 2>/dev/null | sed 's/^/      /'; then
        true
    else
        echo "      (no [[ ]] guards found — loads in all contexts)"
    fi

    log_section "4. Source"
    echo ""
    # shellcheck disable=SC1090
    if source "$pkg_file"; then
        log_pass "Sourced successfully"
    else
        log_fail "Source failed (exit $?)"
        return 1
    fi

    log_section "5. Functions After Source"
    echo ""
    declare -F | grep -E "(set_package_aliases|p_install|p_remove|p_update|p_search|command_check)" \
        | awk '{print "      " $3}' || echo "      (none matching expected pattern)"

    log_section "6. Calling set_package_aliases"
    echo ""
    if declare -f set_package_aliases >/dev/null 2>&1; then
        if DEBUG=1 set_package_aliases; then
            log_pass "set_package_aliases returned 0"
        else
            log_fail "set_package_aliases returned non-zero"
        fi
        echo ""
        log_section "7. Functions After set_package_aliases"
        echo ""
        declare -F | grep -E "(p_install|p_remove|p_update|p_search)" \
            | awk '{print "      " $3}' || true
        if declare -f p_install >/dev/null 2>&1; then
            log_pass "p_install is defined"
        else
            log_fail "p_install NOT defined after set_package_aliases — subshell issue?"
        fi
    else
        log_fail "set_package_aliases not defined — cannot call it"
    fi

    echo ""
}

# =============================================================================
# Help
# =============================================================================
show_brief_help() {
    echo "Usage: ${SCRIPT_NAME} [MODE] [OPTIONS]"
    echo "       ${SCRIPT_NAME} --help for full help"
}

show_help() {
    cat << EOF

${BOLD}${SCRIPT_NAME} v${VERSION}${NC}
Dotfiles diagnostic and test utility.

${BOLD}USAGE${NC}
  ${SCRIPT_NAME} [MODE] [OPTIONS]

${BOLD}MODES${NC}
  (default)   Quick environment sanity check — shell, exports, functions, aliases
  --quick     Same as default
  --test      Full test suite with pass/fail counters
  --pkg       pkg_aliases.bash deep-dive (source + call set_package_aliases)
  --all       Run all three modes in sequence

${BOLD}OPTIONS${NC}
  -h, --help      Show this help
  -?, --info      Show this help
  -v, --version   Show version
  -d, --debug     Enable debug output (set -x)

${BOLD}EXIT CODES${NC}
  0   All checks/tests passed
  1   One or more tests failed
  2   Invalid argument

${BOLD}NOTES${NC}
  For alias checks to work this must run in an interactive shell.
  Alternatively: source it inside your current session.

EOF
}

# =============================================================================
# parse_args
# =============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help|-\?|--info)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "${SCRIPT_NAME} v${VERSION}"
                exit 0
                ;;
            -d|--debug)
                DEBUG=1
                set -x
                ;;
            --quick)
                MODE="quick"
                ;;
            --test)
                MODE="test"
                ;;
            --pkg)
                MODE="pkg"
                ;;
            --all)
                MODE="all"
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_brief_help
                exit 2
                ;;
        esac
        shift
    done
}

# =============================================================================
# validate_environment
# =============================================================================
validate_environment() {
    if [ ! -d "${DOTFILES_D}" ]; then
        echo "ERROR: ${DOTFILES_D} not found — is this repo cloned to ~/.dotfiles?" >&2
        exit 1
    fi
}

# =============================================================================
# cleanup
# =============================================================================
cleanup() {
    : # nothing to clean up — read-only script
}
trap cleanup EXIT INT TERM

# =============================================================================
# main
# =============================================================================
main() {
    parse_args "$@"
    validate_environment

    local exit_code=0

    case "$MODE" in
        quick)
            check_environment
            ;;
        test)
            run_full_tests || exit_code=1
            ;;
        pkg)
            check_pkg_aliases || exit_code=1
            ;;
        all)
            check_environment
            run_full_tests || exit_code=1
            echo ""
            check_pkg_aliases || exit_code=1
            ;;
    esac

    return $exit_code
}

# =============================================================================
# Execution guard
# =============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

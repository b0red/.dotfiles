#!/bin/sh
# If we don't have most(1), we'll just use whatever pager the application or
# system deems fit
command -v most >/dev/null 2>&1 || return

# Use most(1) as my PAGER
PAGER=most
export PAGER

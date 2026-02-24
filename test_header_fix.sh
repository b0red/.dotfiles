#!/bin/bash
# Complete test of add_file_header function

DISTRO="ubuntu"

log() {
    echo "$2: $1"
}

add_file_header() {
    local target_file="$1"
    local creation_date
    creation_date="$(date '+%Y-%m-%d %H:%M:%S')"
    local hostname="${HOSTNAME:-$(hostname)}"
    
    if [ -z "$target_file" ]; then
        log "❌ add_file_header: No target file specified" "error"
        return 1
    fi
    
    if [ ! -f "$target_file" ]; then
        log "⚠️ Target file does not exist: $target_file" "warn"
        return 1
    fi
    
    local temp_file
    if ! temp_file=$(mktemp 2>/dev/null); then
        log "❌ Failed to create temp file" "error"
        return 1
    fi
    
    # Step 1: Check for shebang on line 1
    local shebang=""
    local first_line
    first_line=$(head -n 1 "$target_file")
    if [[ "$first_line" =~ ^#! ]]; then
        shebang="$first_line"
    fi
    
    # Step 2: Find where actual content starts (after shebang and old header)
    local content_start_line=1
    
    # If shebang exists, content is at least line 2
    if [ -n "$shebang" ]; then
        content_start_line=2
    fi
    
    # Check if there's an old RunMe.sh header to skip
    if grep -q "Created by RunMe.sh" "$target_file" 2>/dev/null; then
        log "Updating header in $(basename "$target_file")..." "info"
        
        # Read file line by line starting after shebang
        local line_num=$content_start_line
        local found_header_end=0
        
        while IFS= read -r line; do
            # Check if this line is part of the header
            if [[ "$line" =~ ^###.*-\+- ]] || \
               [[ "$line" =~ ^###.*Created\ by\ RunMe\.sh ]] || \
               [[ "$line" =~ ^###.*Host: ]] || \
               [[ "$line" =~ ^###.*User: ]] || \
               [[ "$line" =~ ^###.*Distro: ]]; then
                # Still in header, skip it
                line_num=$((line_num + 1))
                continue
            elif [[ "$line" =~ ^[[:space:]]*$ ]] && [ $found_header_end -eq 0 ]; then
                # Empty line right after header
                line_num=$((line_num + 1))
                found_header_end=1
                break
            else
                # Found actual content
                break
            fi
        done < <(tail -n +$content_start_line "$target_file")
        
        content_start_line=$line_num
    else
        log "Adding header to $(basename "$target_file")..." "info"
    fi
    
    # Step 3: Build the new file
    {
        # Write shebang if original had one
        if [ -n "$shebang" ]; then
            echo "$shebang"
        fi
        
        # Write new header
        cat << EOF
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by RunMe.sh $creation_date
###                                             Host: $hostname
###                                             User: ${USER:-$(whoami)}
###                                             Distro: $DISTRO
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

EOF
        
        # Write content starting from where header ends
        tail -n +$content_start_line "$target_file"
        
    } > "$temp_file"
    
    # Step 4: Replace original file
    if mv "$temp_file" "$target_file" 2>/dev/null; then
        log "✓ Header updated in $(basename "$target_file")" "success"
        return 0
    else
        log "❌ Failed to update header in $(basename "$target_file")" "error"
        rm -f "$temp_file"
        return 1
    fi
}

# ===== TEST CASES =====

echo "========================================="
echo "TEST 1: File with shebang and old header"
echo "========================================="

cat > test1.sh << 'EOF'
#!/usr/bin/env bash
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
###                                             Created by RunMe.sh 2026-01-22 21:43:07
###                                             Host: DESKTOP-JLMCRD0
###                                             User: patrick
###                                             Distro: ubuntu
### -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

# ~/.bashrc: executed by bash(1) for non-login shells.

echo "Test content"
EOF

echo "--- BEFORE ---"
cat test1.sh
echo ""

add_file_header test1.sh
echo ""

echo "--- AFTER ---"
cat test1.sh
echo ""

echo "--- VERIFICATION ---"
header_count=$(grep -c "Created by RunMe.sh" test1.sh)
echo "Number of headers: $header_count (should be 1)"
shebang_line=$(head -n 1 test1.sh)
echo "Line 1: $shebang_line (should be shebang)"

echo ""
echo "========================================="
echo "TEST 2: Running twice (update header)"
echo "========================================="

sleep 1
add_file_header test1.sh
echo ""

echo "--- AFTER SECOND RUN ---"
cat test1.sh
echo ""

echo "--- VERIFICATION ---"
header_count=$(grep -c "Created by RunMe.sh" test1.sh)
echo "Number of headers: $header_count (should STILL be 1)"
shebang_line=$(head -n 1 test1.sh)
echo "Line 1: $shebang_line (should be shebang)"

# Cleanup
rm -f test1.sh

echo ""
echo "========================================="
echo "TEST COMPLETE"
echo "========================================="
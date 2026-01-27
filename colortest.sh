#!/usr/bin/env bash
# Bash Color Table Generator

# Reset code
RESET="\e[0m"

echo "=== Bash Color Table ==="
echo

# Foreground colors (30–37) and Background colors (40–47)
for style in 0 1 2 4 5 7; do
    case $style in
        0) style_name="Normal" ;;
        1) style_name="Bold" ;;
        2) style_name="Dim" ;;
        4) style_name="Underline" ;;
        5) style_name="Blink" ;;
        7) style_name="Reverse" ;;
    esac
    echo "Style: $style_name"
    for fg in {30..37}; do
        for bg in {40..47}; do
            echo -ne "\e[${style};${fg};${bg}m ${style};${fg};${bg} ${RESET}"
        done
        echo
    done
    echo
done

# Extended 256-color table
echo "=== 256-Color Table ==="
for color in {0..255}; do
    printf "\e[38;5;%sm%3s\e[0m " "$color" "$color"
    if (( (color + 1) % 16 == 0 )); then
        echo
    fi
done

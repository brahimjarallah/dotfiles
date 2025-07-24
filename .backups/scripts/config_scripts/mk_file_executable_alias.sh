#!/usr/bin/env bash

# add this chx function into ~/.zshrc   to make files executable and editable at the same time
#
# inside terminal just type chx file.xx -> it will be executable and editable
#
#
chx() {
  [[ $1 ]] || { echo "Usage: mkshx <file.sh>"; return 1; }
  install -m755 /dev/stdin "$1" <<EOF
#!/usr/bin/env bash
set -euo pipefail

echo "Hello from \$0"
EOF
  ${EDITOR:-nvim} "$1"  # edit file with nvim after making it executable
}





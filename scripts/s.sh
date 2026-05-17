#!/bin/bash

# Server configurations: server_name -> "user@host -p port"
# Copy this file and fill in your own servers.
#
# Usage: s <name>
#   e.g.  s web    → ssh user@web.example.com -p 22
#         s db     → ssh admin@10.0.0.50 -p 2222

case "$1" in
    # === Add your servers below ===

    # web)
    #     ssh user@web.example.com -p 22
    #     ;;
    # db)
    #     ssh admin@10.0.0.50 -p 2222
    #     ;;
    # home)
    #     ssh user@192.168.1.100 -p 22
    #     ;;

    *)
        echo "Unknown server: $1"
        echo "Edit ~/scripts/s.sh to add your servers."
        exit 1
        ;;
esac

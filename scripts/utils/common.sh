#!/bin/bash

set -exuo pipefail

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

as_root() {
    # A function inspired from get.docker.com and https://stackoverflow.com/a/32280085
    # Designed to pick the best way to run a command as root
    set +x      # we don't need to see all this every time
    local shell_cmd
    local cmd
    local user
    cmd=( "$@" )
    shell_cmd='bash -c'
    user="$(id -un 2>/dev/null || true)"

    if [ "$user" != 'root' ]; then
        if command_exists sudo; then
            shell_cmd='sudo -E bash -c'
        elif command_exists su; then
            shell_cmd='su -c'
        else
            cat >&2 <<-'EOF'
            Error: this installer needs the ability to run commands as root.
            We are unable to find either "sudo" or "su" available to make this happen.
EOF
            exit 1
        fi
    fi
    printf -v cmd_str '%s ' "${cmd[@]}"
    set -x
    $shell_cmd "$cmd_str"
}

try_nonroot_first() {
    # Attempts to run a command as is, but if it fails, it tries again using
    # 'as_root`. If it does have to do something as_root, it returns 1, so 
    # any other things that need doing (such as chowning) can be done.
    # returning 1 for a "successful" command is a bit weird tho...
    set +x
    local cmd
    cmd=( "$@" )
    printf -v cmd_str '%s ' "${cmd[@]}"
    bash -c "$cmd_str" || {
        as_root "$@";
        set -x
        return 1
    }
    set -x
    return 0
}

chown_dir_to_user() {
    set +x
    as_root chown -R "$(id -u)":"$(id -g)" "$1"
    set -x
}

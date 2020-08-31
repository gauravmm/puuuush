function puuuush {
    source ~/.puuuush

    if [[ -z "$PUUUUSH_SERVER" ]]; then
        echo "~/.puuuush does not define necessary variables. Update that and try again."
        return
    fi

    local pushstr="$(date +%s)/"
    for arg in "$@"; do
        pushstr="$pushstr$(echo -ne $arg | xxd -plain | tr -d '\\n' | sed 's/\\(..\\)/%\\1/g')/"
    done
    local sig=$(echo -ne "$PUUUUSH_DEVICE_SHARED_SECRET/$pushstr" | sha224sum | cut -d" " -f1)
    wget -qO - "$PUUUUSH_SERVER/do/$PUUUUSH_USER_ID/$PUUUUSH_DEVICE_ID/$sig/$pushstr" # 1>/dev/null
};

function puuuush@pid@impl {
    if [[ -z "$1" ]]; then
        echo "Missing pid."
        return
    fi
    if [[ ! -d "/proc/$1" ]]; then
        echo "No such process."
        return
    fi
    message="$2"
    if [[ -z "$2" ]]; then
        message="Command completed: $(head -n1 /proc/$1/cmdline)"
    fi
    # Active waiting, because there is no guarantee on how we got the PID:
    # We can only use wait if the process was spawned by the shell
    # and not the subshell we're currently in.
    while [ -e /proc/"$1" ];
        do sleep 10;
        # Kill switch -- in case you want to stop all pending waiting processes.
        if [ -e "$HOME/puuuush.kill" ]; then
            return
        fi
    done
    command_rv=$?
    puuuush "Command completed ($command_rv)" $message > /dev/null
}

function puuuush@pid {
    # Push on process termination. Expects a single PID as an argument, and sends a push
    # with the image name when that PID exits.
    if [[ -z "$1" ]]; then
        echo "Missing pid. Usage: puuuush@pid pid [message]"
        return
    fi

    if [ -e "$HOME/puuuush.kill" ]; then
        echo "The kill switch file at ~/puuuush.kill exists. You should remove that before running this."
        return
    fi

    # We use the double-fork trick to get a background process without job control.
    # The `nohup` part allows the process to continue even when the user logs off.
    # You may need to change the path to the scripts. There's no reliable way to get the currently executing script
    # in all the major shells.
    (( nohup bash -c "source ~/.scripts/puuuu.sh; puuuush@pid@impl $@" ) & )
};

function puuuush@cuda {
    # Add notifications for when any currently executing CUDA process terminates.
    if ! which nvidia-smi; then
        echo "Missing nvidia-smi."
        return
    fi

    # Get the table of processes, as a semicolon-separated string:
    # PID, mode, command, memory
    NVIDIA_PROCESSES=$(nvidia-smi -q -d PIDS | grep "^        " | sed -re "s/ *(Type|Name|Used GPU Memory) *: /;/g" -e "s/ *Process ID *: /???/" | sed -ze "s/\n//g" -e "s/???/\n/g")
    # Get the current user id, so we can only report their processes:
    CURR_UID=$(id -u)

    while IFS=";" read -r PID MODE CMD MEM; do
        if [[ -z "$PID" ]]; then
            continue
        fi
        MEM="${MEM% MiB}"
        OWNER_UID="$(cat /proc/$PID/loginuid)"
        # Only care about processes from the current user:
        if [[ "$OWNER_UID" -ne "$CURR_UID" ]]; then
            continue
        fi
        # Only select Python processes:
        if ! [[ "$CMD" == *"python"* ]]; then
            continue
        fi
        # Only select processes that use at least 128 MiB of CUDA memory:
        if [[ "$MEM" -lt 128 ]]; then
            continue
        fi

        # Great! We can wait on this PID:
        FULLCMD="$(cat /proc/$PID/cmdline)"
        printf "NOTIFYING (% 6d)\t%s\n" "$PID" "$FULLCMD"
        puuuush@pid "$PID" "CUDA process completed: $FULLCMD"

    done <<< "$NVIDIA_PROCESSES"
};


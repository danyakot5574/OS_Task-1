#!/bin/bash

show_users() {
    echo "Список пользователей и их домашние директории:"
    awk -F: '$3 >= 1000 && $7 !~ /(nologin|false)/ {print $1 " -> " $6}' /etc/passwd | sort
}

show_processes() {
    echo "Список процессов (PID : команда):"
    ps -eo pid,comm --sort=pid
}

show_help() {
    cat <<EOF
Использование: $0 [ОПЦИИ]

Доступные аргументы:
  -u, --users             Вывести список пользователей и их домашние директории
  -p, --processes         Вывести список запущенных процессов
  -l PATH, --log PATH     Перенаправить стандартный вывод (stdout) в файл PATH
  -e PATH, --errors PATH  Перенаправить поток ошибок (stderr) в файл PATH
  -h, --help              Вывести эту справку и завершить выполнение

Примеры:
  $0 -u
  $0 --processes --log processes.txt
  $0 -u -l out.txt -e err.txt
EOF
}

check_path_access() {
    local path="$1"
    local mode="$2"

    if [[ "$mode" == "w" ]]; then
        local dir
        dir=$(dirname -- "$path")
        if [[ ! -d "$dir" || ! -w "$dir" ]]; then
            echo "Ошибка: нет прав на запись в '$dir'" >&2
            exit 1
        fi
    elif [[ "$mode" == "r" ]]; then
        if [[ ! -r "$path" ]]; then
            echo "Ошибка: нет прав на чтение '$path'" >&2
            exit 1
        fi
    fi
}

# ---

LOG_FILE=""
ERR_FILE=""

args=("$@")
len=${#args[@]}
i=0
while [[ $i -lt $len ]]; do
    arg="${args[i]}"
    case "$arg" in
        -l|--log)
            next_index=$((i + 1))
            if [[ $next_index -ge $len ]]; then
                echo "Ошибка: отсутствует путь для $arg" >&2
                exit 1
            fi
            next="${args[next_index]}"
            if [[ "$next" == -* ]]; then
                echo "Ошибка: неверный путь для $arg: '$next'" >&2
                exit 1
            fi
            LOG_FILE="$next"
            check_path_access "$LOG_FILE" "w"
            i=$((i + 2))
            ;;
        -e|--errors)
            next_index=$((i + 1))
            if [[ $next_index -ge $len ]]; then
                echo "Ошибка: отсутствует путь для $arg" >&2
                exit 1
            fi
            next="${args[next_index]}"
            if [[ "$next" == -* ]]; then
                echo "Ошибка: неверный путь для $arg: '$next'" >&2
                exit 1
            fi
            ERR_FILE="$next"
            check_path_access "$ERR_FILE" "w"
            i=$((i + 2))
            ;;
        *)
            i=$((i + 1))
            ;;
    esac
done

if [[ -n "$LOG_FILE" ]]; then
    exec >"$LOG_FILE" || { echo "Ошибка: не могу открыть для записи '$LOG_FILE'" >&2; exit 1; }
fi
if [[ -n "$ERR_FILE" ]]; then
    exec 2>"$ERR_FILE" || { echo "Ошибка: не могу открыть для записи '$ERR_FILE'" >&2; exit 1; }
fi

TEMP=$(getopt -o upl:e:h --long users,processes,log:,errors:,help -n "$0" -- "$@")
if [[ $? != 0 ]]; then
    echo "Ошибка: неверные аргументы. Используйте --help для справки." >&2
    exit 1
fi

eval set -- "$TEMP"

ACTION=""

while true; do
    case "$1" in
        -l|--log)
            shift 2
            ;;
        -e|--errors)
            shift 2
            ;;
        -u|--users)
            ACTION="users"
            shift
            ;;
        -p|--processes)
            ACTION="processes"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Неизвестный аргумент: $1" >&2
            exit 1
            ;;
    esac
done

case "$ACTION" in
    users)
        show_users
        ;;
    processes)
        show_processes
        ;;
    *)
        echo "Не указано действие. Используйте -h для справки." >&2
        exit 1
        ;;
esac

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
  -u, --users         Вывести список пользователей и их домашние директории
  -p, --processes     Вывести список запущенных процессов
  -l PATH, --log PATH Перенаправить стандартный вывод (stdout) в файл PATH
  -e PATH, --errors PATH Перенаправить поток ошибок (stderr) в файл PATH
  -h, --help          Вывести эту справку и завершить выполнение

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
        dir=$(dirname "$path")
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

TEMP=$(getopt -o upl:e:h --long users,processes,log:,errors:,help -n "$0" -- "$@")
if [[ $? != 0 ]]; then
    echo "Ошибка: неверные аргументы. Используйте --help для справки." >&2
    exit 1
fi

eval set -- "$TEMP"

LOG_FILE=""
ERR_FILE=""

while true; do
    case "$1" in
        -u|--users)
            ACTION="users"
            shift
            ;;
        -p|--processes)
            ACTION="processes"
            shift
            ;;
        -l|--log)
            LOG_FILE="$2"
            check_path_access "$LOG_FILE" "w"
            exec >"$LOG_FILE"
            shift 2
            ;;
        -e|--errors)
            ERR_FILE="$2"
            check_path_access "$ERR_FILE" "w"
            exec 2>"$ERR_FILE"
            shift 2
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


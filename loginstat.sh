#!/bin/bash

param=$1
script_name=$0

function print_help() {
  echo -e "Usage: ${script_name} [-h] [username] [date(mm:dd:hh:mm)]
Print login statistics for user or for a date

  -h\t\tprint this help message"
}

# Input: n(umber) Output: nth
function nth_day_format() {
  case "${1: -1}" in
    1)
      echo "${1}st"
      ;;
    2)
      echo "${1}nd"
      ;;
    3)
      echo "${1}rd"
      ;;
    *) echo "${1}th" ;;
  esac
}

# Convert month number to month name
# Input: number Output: month_name
function name_of_month() {
  local months=("January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December")

  echo "${months[$1 - 1]}"
}

function parse_parameters() {
  if [[ $# -lt 1 ]]; then
    echo "${script_name}: Not enough parameters"
    echo "Try '${script_name} -h' for more information"
    exit 1
  fi
  if [[ ${1:0:1} == "-" ]]; then
    if [[ ${1:1:1} != "h" ]]; then
      echo "${script_name}: invalid option -- '${1:1:1}'"
      echo "Try '${script_name} -h' for more information"
      exit 1
    else
      print_help
      exit 0
    fi
  fi
}

function print_for_date() {
  local username_list=$(last -p "$1 $2" | head -n -2 | tr -s " " | cut -d " " -f 1 | uniq)

  local month=$(name_of_month $(echo $1 | cut -d "-" -f 2))
  local day=$(nth_day_format $(echo $1 | cut -d "-" -f 3))
  local hour=$(echo $2 | cut -d ":" -f 1)
  local minute=$(echo $2 | cut -d ":" -f 2)

  echo "On the ${day} of ${month} at ${hour}:${minute} the following users were logged in:"

  IFS=$'\n'
  for un in ${username_list}; do
    name="$(getent passwd ${un} | cut --output-delimiter="|" -d ":" -f 1,5 | tr "|" "\t")"
    echo "${name}"
  done
}

function last_login() {
  echo "Last Login: $(last -an 1 "$1" | head -n -2 | tr -s " " | cut -d " " -f 4-9)"
  echo "Machine: $(last -adn1 "$1" | head -n -2 | tr -s " " | rev | cut -d " " -f 1 | rev)"
}

function ten_most_used() {
  local machine_list=$(last -ad "$1" | head -n -2 | rev | cut -d " " -f 1 | rev | sort | uniq -c | sort -nr | head -n 10 | tr -s " " | cut -d " " -f 3)

  echo -e "\n10 most used machines for logging in:"
  echo "${machine_list}"
}

# converts hh:mm time to minutes
function hhmm_to_mm() {
  local hour=$(echo $1 | cut -d ":" -f 1)
  local minute=$(echo $1 | cut -d ":" -f 2)

  echo "$(echo "${hour} * 60 + ${minute}" | bc)"
}

# convert minutes to hh:mm
function mm_to_hhmm() {
  local hour=$(echo "scale = 4;$1/60" | bc | cut -d "." -f 1)
  local minute=$(echo "0.$(echo "scale = 4;$1/60" | bc | cut -d "." -f 2)*60" | bc | cut -d "." -f 1)

  # Change hour to 0 if empty because bc doesn't print leading 0
  if [ -z ${hour} ]; then
    hour="0"
  fi
  # Same for minutes
  if [ -z ${minute} ]; then
    minute="0"
  fi

  echo "${hour}:${minute}"
}

function avarages() {
  local total_minutes=0

  local time_list=$(last $1 | head -n -2 | grep "([0-9][0-9]:[0-9][0-9])" | tr -s " " | rev | cut -d " " -f 1 | rev | tr -d "()")

  IFS=$'\n'
  for t in ${time_list}; do
    min=$(hhmm_to_mm $t)
    total_minutes=$(echo "${total_minutes}+${min}" | bc)
  done

  # time per logins
  local n_logins=$(last $1 | head -n -2 | grep "([0-9][0-9]:[0-9][0-9])" | wc -l)
  local hours_per_logins=$((${total_minutes} / ${n_logins}))
  echo -e "\nHours/Logins: $(mm_to_hhmm ${hours_per_logins})"

  # Logins per days
  local n_days=$(last ${1} | head -n -2 | rev | tr -s " " | cut -d " " -f 5-7 | rev | uniq | wc -l)
  echo "Logins/Days: $((n_logins / n_days))"

  # time per days
  local hours_per_days=$((${total_minutes} / n_days))
  echo "Hours/Days: $(mm_to_hhmm ${hours_per_days})"
}

parse_parameters $*

# Given parameter is a date
if [[ ${param} =~ ^[0-1][0-9]:[0-3][0-9]:[0-2][0-9]:[0-6][0-9]$ ]]; then
  # Defaulting to current year
  year=$(date "+%Y")
  month=$(echo ${param} | cut -d ":" -f 1)
  day=$(echo ${param} | cut -d ":" -f 2)
  hour=$(echo ${param} | cut -d ":" -f 3)
  minute=$(echo ${param} | cut -d ":" -f 4)

  # Formatting date for last
  date_string="${year}-${month}-${day} ${hour}:${minute}"

  # Check if date is invalid
  last -p "${date_string}" > /dev/null 2>&1
  if [ $? -eq 1 ]; then
    echo "Invalid date"
    exit 1
  fi

  # Check if there were any users logged in on that date
  if [ $(last -p "${date_string}" | wc -l) -lt 3 ]; then
    echo "There weren't any users logged in on that date"
    exit 1
  fi
  print_for_date ${date_string}
# Given parameter is a username
else
  if [ $(last ${param} | wc -l) -lt 3 ]; then
    echo "${param} user haven't logged in on this computer yet"
    exit 1
  fi

  last_login ${param}
  ten_most_used ${param}
  avarages ${param}
fi

#!/bin/bash

# This script creates a new user on the local system.
# You must supply a username as an argument to the script.
# Optionally, you can also provide your own password and a comment for the account (full name).

usage() {
  # Display the usage and exit.
  echo "Usage: ${0} [-p] USER_NAME [PASSWORD] [COMMENT]..." >&2
  echo "Create an account on the local system with the name of USER_NAME, your own password and a comments field of COMMENT." >&2
  echo "  -p PASSWORD   Add your own password to the account." >&2
  exit 1
}

# Make sure the script is being executed with superuser privileges.
if [[ ""${UID} -ne 0 ]]
then
  echo "Please run as root." >&2
  exit 1
fi

# If the user doesn't supply at least one argument, then give them help.
if [[ "${#}" -lt 1 ]]
then
  usage
fi

# Parse the option
while getopts p OPTION
do
  case ${OPTION} in
    p)
      shift
      # The first parameter is the user name.
      USER_NAME=${1}
      shift

      if [[ "${#}" -lt 1 ]]
      then
        usage
      fi
      echo "${1}"
      PASSWORD=${1}
      OWN_PASSWORD='true'
      shift
      ;;
    ?) usage ;;
  esac
done

# The first parameter is the user name.
if [[ ${OWN_PASSWORD} != 'true' ]]
then
  USER_NAME=${1}
  shift
fi

# The rest of the parameters are for the account comments.
COMMENT=${@}

# Generate a password if you do not add own password.
if [[ ${OWN_PASSWORD} != 'true' ]]
then
  PASS1=$(date +%s%N | sha256sum | head -c15)
  PASS2=$(echo '!@#$%^&*' | fold -w1 | shuf | head -c1)
  PASSWORD="${PASS1}${PASS2}"
fi

echo "${USER_NAME}  ${PASSWORD}  ${COMMENT}"

# Create the user with the password.
useradd -c "${COMMENT}" -m ${USER_NAME} &> /dev/null

# Check to see if the useradd command succeeded.
if [[ "${?}" -ne 0 ]] 
then
  echo "Something has gone wrong - the account could not be created." >&2
  exit 1
fi

# Set the password.
echo ${PASSWORD} | passwd --stdin ${USER_NAME} &> /dev/null

# Check to see if the passwd command succeeded.
if [[ "${?}" -ne 0 ]]
then
  echo "Something has gone wrong - the password for the account could not be set." >&2
  exit 1
fi

# Force password change on first login.
if [[ ${OWN_PASSWORD} != 'true' ]]
then
  passwd -e ${USER_NAME} &> /dev/null
fi

# Display the username, password, and the host where the user was created.
echo
echo 'username:'
echo "${USER_NAME}"
echo
echo 'password:'
echo "${PASSWORD}"
echo
echo 'host:'
echo "${HOSTNAME}"
echo

exit 0



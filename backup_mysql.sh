#!/bin/bash
# backup_mysql - A simple MySQL/MariaDB backup script for cPanel servers
# Nathan Paton <nathanpat@inmotionhosting.com>
# v0.1 (Updated on 1/21/2023)

# This script requires a cPanel server. Might support non-cPanel servers later.
if ! [[ -x /usr/local/cpanel/bin/whmapi1 ]]; then
  echo "Couldn't locate the WHM API. This script requires a cPanel server to work."

  exit
fi

# Text formatting
TEXT_BOLD="\e[1m"
TEXT_RESET="\e[0m"

# Version. Duh.
VERSION="v0.1 (Updated on 1/21/2023)"

# Help message
HELP_MESSAGE="USAGE: backup_mysql [-h]
  -f --force              [TODO] Use 'mysqldump -f' to force exports.
  -h --help               Show this message and exit.
  -v --version            Show version information and exit.
  -t --tesla              Summon a random Tesla and exit. Does not support Roadsters."

# Command options. This is mostly to use the --force.
while [[ "${#}" -gt 0 ]]; do
  case "${1}" in
    # Show help and exit
    -h|--help)
      echo "${HELP_MESSAGE}"

      exit
    ;;

    # Show version and exit
    -v|--version)
      echo "${VERSION}"

      exit
    ;;

    # Show help and exit for invalid commands
    -*)
      echo "${HELP_MESSAGE}"

      exit
    ;;
  esac
done

# In case whmapi1 isn't in our path for some reason
whmapi1_cmd() {
  /usr/local/cpanel/bin/whmapi1 "${@}"
}

# This script is extra awesome because it checks the actual SQL server kind
MYSQL_KIND="$(whmapi1_cmd current_mysql_version | grep server: | awk -F ': ' '{print $2}')"
if [[ "${MYSQL_KIND}" == "mariadb" ]]; then
  MYSQL_KIND="MariaDB"
elif [[ "${MYSQL_KIND}" == "mysql" ]]; then
  MYSQL_KIND="MySQL"
else
  # Should never happen, but *shrug*
  MYSQL_KIND="Unknown"
fi

# This script is different than some in that it also backs up the entire MySQL
# install dir (for easy rollbacks). We need to take the SQL server down to
# avoid corruption. Should be quick, but some installs are bigly.
echo -e "${TEXT_BOLD}Heads up!${TEXT_RESET} This script takes a complete backup of ${MYSQL_KIND}. The ${MYSQL_KIND} server will be down for some of this. Bail out if now's not a good time.\n"

# Create our backup directory (or handle errors creating/cd'ing into it)
# Now a function for saner code reading
make_dir() {
  # Handle existing dirs and offer up the read prompt again
  # And if something goes wrong creating the non-existent dir, bail out
  if [[ -d "${BACKUP_DIR}" ]]; then
    echo -e "Looks like ${BACKUP_DIR} already exists. Use something else.\n"
  elif ! mkdir -p "${BACKUP_DIR}"; then
    echo -e "${TEXT_BOLD}Uh-oh!${TEXT_RESET} Unable to create ${BACKUP_DIR} for some reason. Bailing out."

    exit
  # Same if we can't cd into it for some reason
  elif ! cd "${BACKUP_DIR}"; then
    echo -e "${TEXT_BOLD}Uh-oh!${TEXT_RESET} Unable to change into ${BACKUP_DIR} for some reason. Bailing out."

    exit
  else
    # If all was good, break the while loop below and start
    return 1
  fi
}

# Get our backup dir. We use a while loop in case the user foobars something
# and we need to ask for a different dir name/path.
# Or if the user wants to bail out now, there's also an option for that
while true; do
  read -rp "Dumping Ground (or \"Bail\") [mysql_backup.$(date -I)]: " BACKUP_DIR

  # We need to do some case-insensitive regex below
  # This isn't the best way to go about it (using shopt? seriously?), but I
  # think the 'correct' method looks god awful.
  if shopt nocasematch | grep -q off; then
    shopt -s nocasematch
  fi

  # Bail out if the user says one of these magic words
  # This is also the most advanced regex I have ever written
  if [[ "${BACKUP_DIR}" =~ bail|quit|exit|q ]]; then
    # No more regex needed in this script
    if shopt nocasematch | grep -q on; then
      shopt -u nocasematch
    fi

    echo -e "Roger that. No changes made."

    exit
  # Create the dir the user entered in the above prompt
  elif [[ -n "${BACKUP_DIR}" ]]; then

    make_dir || break
  # Or create a dir with our default name instead if nothing was given
  elif [[ -z "${BACKUP_DIR}" ]]; then
    BACKUP_DIR="mysql_backup.$(date -I)"

    make_dir || break
  fi
done

echo -e "Exporting databases to disk...\n"

# Get our list of databases and start dumping them to disk
# We can't dump information_schema and performance_schema, so we exclude them
for DATABASE in $(mysql -Ne 'SHOW DATABASES;' | grep -Ev 'information_schema|performance_schema'); do
  # TODO: Handle errors from mysqldump and offer a --force option
  mysqldump "${DATABASE}" > "${DATABASE}".sql

  # We also dump the database names to a file for easy scripting if needed
  echo "${DATABASE}" >> databases.txt
  echo "Done: ${DATABASE}"
done

echo -e "\nBacking up /var/lib/mysql/..."

# Disable monitoring so chkservd doesn't restart MySQL on us
whmapi1_cmd configureservice service=mysql enabled=1 monitored=0 > /dev/null

# Bring MySQL down _nicely_
# TODO: Add handling for if this fails for some reason
/scripts/restartsrv_mysql --stop > /dev/null

rsync -aR /var/lib/mysql .

# And now we bring MySQL back up and re-enable monitoring
# TODO: Add handling for if this fails for some reason
whmapi1_cmd configureservice service=mysql enabled=1 monitored=1 > /dev/null

/scripts/restartsrv_mysql --start > /dev/null

echo -e "Backing up cPanel user database information..."

# This copies the cPanel user database details (ownership, etc.)
# Not necessarily needed, but might as well for completeness sake
rsync -aR /var/cpanel/databases .

# And now we're all done. Blessed be the Beefy Miracle.
# TODO: Add a fail condition message
echo -e "\n${TEXT_BOLD}Success!${TEXT_RESET} ${MYSQL_KIND} has been successfully backed up. Have a beefy day."

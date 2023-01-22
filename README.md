Bash script for cPanel servers to take a complete backup of MySQL/MariaDB. Based on my [original backup script](https://github.com/tchbnl/random).

```
# backup_mysql
Heads up! This script takes a complete backup of MariaDB. The MariaDB server will be down for some of this. Bail out if now's not a good time.

Dumping Ground (or "Bail") [mysql_backup.2023-01-21]:
Exporting databases to disk...

Done: cphulkd
Done: leechprotect
Done: modsec
Done: mysql
Done: roundcube
Done: thisdo7_wordpress

Backing up /var/lib/mysql/...
Backing up cPanel user database information...

Success! MariaDB has been successfully backed up. Have a beefy day.
```

This script uses the cPanel API for some things, like disabling chkservd monitoring and stopping/restarting the SQL server. I might rework it to support non-cPanel servers, but this was the easiest thing for me to do.

This script also takes a complete backup of /var/lib/mysql/ to make it easier to roll-back in case something went catastrophically wrong when upgrading. I recommend making sure there's enough space first for both the dumps and install copy before running this. In the future I might add some basic checks to help.

There's support for creating a suggested directory and also entering a custom directory and path (with checks to make sure this works). This script should work fine in most cases and has been tested. I plan to add support for handling of mysqldump errors/a force dump mode, as well as a simpler mode to just run mysqldump and skip all the other steps if that's all that's needed.

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

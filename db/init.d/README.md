The 01-init.sh script was made to be used with a dump obtained with this command:

```bash
pg_dump [connection params] --create --clean --no-acl --no-owner --file=/full/path/datachile_dump.custom datachile
```

The `--file` parameter is the full path to where the data will be saved.
The output file must be placed in this folder before running `docker-compose`.

Alternatively, if there are no conflicts between usernames and permissions, you can export the whole database in a custom compressed format, made by postgres, using this command:

```bash
pg_dump [connection params] --format=c --file=/full/path/datachile_dump.custom datachile
```

This command ignores all the other flags and creates an exact copy of the database. It's useful to have a backup of the production database too.

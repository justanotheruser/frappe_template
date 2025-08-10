Before creating any sites, make sure `root` user has priveledges (when connecting from dev container).
- run `ip addr` inside `app` container
- get its ip address (e.g. `172.19.0.4`)
- attach shell to MariaDB container
- loging as root
- run
    ```
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.19.0.4' IDENTIFIED BY 'secret' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
    ```
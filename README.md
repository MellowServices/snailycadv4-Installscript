# READ ME

This script is designed to automate the setup process for the SnailyCADv4 project. It installs the necessary packages, sets up a PostgreSQL database, clones the project repository, updates the environment variables, installs dependencies, and builds the project. Finally, it starts the SnailyCADv4 server using PM2.

Thanks to CasperTheGhost for making this amazing CAD! Check him out --> https://github.com/Dev-CasperTheGhost

## Prerequisites

- This script is intended for use on a Linux system.
- Ensure that you have the necessary permissions to install packages and execute commands with `sudo`.

## Instructions

1. Copy the script code and save it to a file, e.g., `setup_script.sh`.
2. Open a terminal and navigate to the directory where you saved the script.
3. Make the script file executable by running the following command:
   ```
   chmod +x setup_script.sh
   ```
4. Run the script using the following command:
   ```
   ./setup_script.sh
   ```

## What the Script Does

1. Checks if the script has already been run by looking for the presence of a `startup_check.txt` file in the `/opt/mellowservices` directory. If the file exists, the script exits.
2. Creates the `startup_check.txt` file to mark that the script has run.
3. Installs the required packages, including `git`, `nodejs`, `yarn`, `net-tools`, `postgresql`, and `postgresql-contrib`.
4. Starts and enables the PostgreSQL service.
5. Sets up the database by creating a user, assigning superuser privileges, and creating a database.
6. Clones the SnailyCADv4 project repository from GitHub.
7. Updates the `.env` file with the necessary configuration, such as the database details, CORS origin URL, and client URLs.
8. Installs project dependencies using `yarn`.
9. Builds the project using Turbo and the provided build filters.
10. Installs PM2 globally.
11. Starts the SnailyCADv4 server using PM2 with the name "SnailyCADv4".

## Note

- Ensure that you have a working internet connection for package installation and repository cloning.
- The script retrieves the IP address assigned to the `eth0` network interface to use in the configuration. If you have a different network interface or want to use a specific IP address, modify the script accordingly.
- It's important to review and update the values in the `.env` file after running the script to ensure they match your desired configuration.

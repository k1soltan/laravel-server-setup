
# Laravel Server Setup Script with Menu

Automated Laravel server setup and configuration script.

This script is a robust and flexible tool designed to automate the setup of a Laravel project on a server. 
It handles everything from server configuration, Laravel installation, Nginx setup, Git operations, 
and permission management, making it ideal for both local development and live server environments.

---

## Features

### Main Features
- **Run All Steps**: Perform all setup tasks in sequence, from server setup to Git integration.
- **Individual Setup Options**:
  - Laravel Project Setup
  - Server Configuration
  - Nginx Configuration
  - Git Operations
  - Permission Correction
- **Revert Options**:
  - Revert Laravel Project
  - Revert Server Setup
  - Revert Nginx Configuration
  - Revert Git Configuration
- **Flexible Git Operations**:
  - Pull changes from a remote repository (hard reset to sync).
  - Push changes to a remote repository (force-push to overwrite remote).
- **Dynamic Permission Correction**:
  - Apply correct permissions based on local or server environments.
  - Option to specify a custom path for permissions.

### Menu-Driven Workflow
The script includes an intuitive menu system, allowing you to:
- Execute all steps in sequence or run specific steps.
- Skip, overwrite, or exit based on existing setups.
- Maintain flexibility and control over every setup aspect.

---

## Prerequisites

Before using the script, ensure the following:

- **Server Requirements**:
  - Ubuntu Linux (or compatible distribution)
  - Root or sudo access
- **Dependencies Installed**:
  - `curl`, `git`, `composer`, `npm` (if not installed, the script will handle this).
- **Valid Domain**:
  - For Nginx setup, ensure your domain points to the server IP.

---

## Usage

### Download the Script
\`\`\`bash
curl -O https://github.com/k1soltan/laravel-server-setup/blob/main/laravel_server_setup_with_menu.sh
chmod +x laravel_server_setup_with_menu.sh
\`\`\`

### Run the Script
\`\`\`bash
sudo ./laravel_server_setup_with_menu.sh
\`\`\`

### Select Options from the Menu
The script provides a menu for step-by-step execution or running all steps in sequence.

---

## Menu Options

1. **Run All Steps**: Executes all steps in sequence (Server Setup, Laravel, Nginx, Git, and Permissions).
2. **Setup Laravel Project**: Installs Laravel in the specified directory and sets up initial permissions.
3. **Setup Server**: Configures the server with:
   - PHP, MySQL, Redis, Nginx, Composer, Node.js, and phpMyAdmin.
4. **Setup Nginx**: Creates a new Nginx server block for your domain and configures it for Laravel and phpMyAdmin.
5. **Perform Git Operations**:
   - Pull changes from a remote repository with a hard reset.
   - Push local changes to the remote repository with a force-push.
6. **Correct Permissions**:
   - Dynamically correct permissions for Laravel directories (`storage` and `bootstrap/cache`).
   - Allows specifying a custom path for permissions.
7. **Revert Options**:
   - Revert Laravel project, server setup, Nginx configuration, or Git initialization.

---

## Configuration Details

### Default Paths and Variables
- **Laravel Project Path**:
  - Default: `/home/<username>/<project_name>`
  - Customizable during the setup process.
- **MySQL Root User**:
  - Default Password: `Matrix123!`
- **PHP Version Detection**:
  - Automatically detects and uses the installed PHP version.

### Permission Correction Rules
- **Live Server**:
  - Owner: `root:www-data`
  - Permissions: 775
  - Group Sticky Bit: g+s
- **Local Environment**:
  - Owner: `<username>:www-data`
  - Permissions: 775
  - Group Sticky Bit: g+s

---

## Error Handling

The script handles common errors gracefully:
- **Git Conflicts**:
  - Prompts users to resolve conflicts manually if pull/push operations fail.
- **Missing Dependencies**:
  - Automatically installs missing packages during server setup.
- **Permission Denials**:
  - Ensures Laravel directories have the correct ownership and permissions.

---

## Customization

You can customize the script by:
- Modifying default paths (`PROJECT_PATH`, `DOMAIN_CONF`).
- Changing MySQL root password (`MYSQL_ROOT_PASSWORD`).
- Adjusting Nginx server block templates.

---

## Example Usage

### Typical Workflow
#### Run All Steps:
\`\`\`bash
Select Option: 1
\`\`\`

#### Perform Git Operations:
After setup, choose option `5` to sync your project with the remote repository:
- **Pull**:
  \`\`\`bash
  Select Option: 5
  Enter 'pull'
  \`\`\`
- **Push**:
  \`\`\`bash
  Select Option: 5
  Enter 'push'
  \`\`\`

#### Correct Permissions:
Use option `6` to correct permissions after making changes.

---

## Troubleshooting

- **502 Bad Gateway (Nginx)**:
  Ensure `php-fpm` service is running:
  \`\`\`bash
  sudo systemctl restart php<version>-fpm
  \`\`\`
- **MySQL Root Access Denied**:
  Ensure the root user is configured for `mysql_native_password`:
  \`\`\`sql
  ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Matrix123!';
  FLUSH PRIVILEGES;
  \`\`\`

---

## Contributions

Feel free to fork this repository, suggest improvements, or report issues via [GitHub Issues](https://github.com/k1soltan/laravel-server-setup/issues).

---

## License

This script is released under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Author

Created by [K1soltan](https://github.com/k1soltan).

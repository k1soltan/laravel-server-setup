#!/bin/bash

# Prompt for project details
read -p "Enter Laravel project name: " PROJECT_NAME
read -p "Enter domain name (e.g., laravel.local): " DOMAIN_NAME
read -p "Enter the username for the environment (e.g., your Ubuntu username): " USER_NAME
read -p "Enter the full project path (default: /home/$USER_NAME/$PROJECT_NAME): " PROJECT_PATH
PROJECT_PATH=${PROJECT_PATH:-/home/$USER_NAME/$PROJECT_NAME}
read -p "Enter your GitHub repository URL (leave blank to skip Git setup): " REPO_URL

# Define paths and variables
NGINX_MAIN_CONF="/etc/nginx/sites-available/host"
DOMAIN_CONF="/etc/nginx/sites-available/${DOMAIN_NAME}"
MYSQL_ROOT_PASSWORD="Matrix123!"

# Get the installed PHP version
PHP_VERSION=$(php -v | grep -oP "^PHP \K[0-9]+\.[0-9]+")

# Function to handle user choices
handle_existing_step() {
    local step_name=$1
    read -p "$step_name already exists. Overwrite (o), Skip and Continue (s), or Skip and Exit (e)? [o/s/e]: " choice
    case $choice in
        o|O) return 0 ;; # Overwrite
        s|S) return 1 ;; # Skip and continue
        e|E) echo "Exiting setup."; exit 0 ;; # Skip and exit
        *) echo "Invalid choice. Exiting."; exit 1 ;;
    esac
}

# Function to set up Laravel project
setup_laravel() {
    if [ -d "$PROJECT_PATH" ]; then
        handle_existing_step "Laravel project directory"
        if [ $? -eq 0 ]; then
            echo "Overwriting Laravel project at $PROJECT_PATH..."
            sudo rm -rf "$PROJECT_PATH"
        else
            echo "Skipping Laravel setup and continuing."
            return
        fi
    fi

    echo "Creating Laravel project at $PROJECT_PATH..."
    composer create-project --prefer-dist laravel/laravel "$PROJECT_PATH"
    echo "Laravel project created."

    echo "Setting permissions for storage and bootstrap/cache..."
    chmod -R 775 "${PROJECT_PATH}/storage" "${PROJECT_PATH}/bootstrap/cache"
    echo "Permissions set."
}

# Revert Laravel setup
revert_laravel() {
    echo "Reverting Laravel project setup..."
    sudo rm -rf "$PROJECT_PATH"
    echo "Laravel project removed."
}

# Function to set up the server
setup_server() {
    echo "Checking if server setup is already completed..."

    if command -v nginx >/dev/null && command -v php >/dev/null && command -v mysql >/dev/null && command -v redis-cli >/dev/null && command -v composer >/dev/null; then
        handle_existing_step "Server setup"
        if [ $? -eq 1 ]; then
            echo "Skipping server setup and continuing."
            return
        fi
    fi

    echo "Updating and upgrading the system..."
    sudo apt update && sudo apt upgrade -y

    echo "Installing Nginx..."
    sudo apt install -y nginx

    echo "Installing PHP and extensions..."
    sudo apt install -y php-cli php-fpm php-mbstring php-xml php-curl php-bcmath php-zip php-soap php-mysql php-tokenizer php-redis unzip curl git

    echo "Installing MySQL Server..."
    sudo apt install -y mysql-server
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;"

    echo "Installing Node.js and npm..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs

    echo "Installing Redis..."
    sudo apt install -y redis
    sudo systemctl enable redis
    sudo systemctl start redis

    echo "Installing Composer..."
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    composer --version

    echo "Installing phpMyAdmin..."
    sudo apt install -y phpmyadmin

    if [ -d "/usr/share/phpmyadmin" ]; then
        echo "Linking phpMyAdmin to Nginx..."
        sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
    else
        echo "phpMyAdmin installation directory not found. Skipping linking step."
    fi

    echo "Configuring UFW firewall..."
    sudo ufw allow OpenSSH
    sudo ufw allow 'Nginx HTTP'
    sudo ufw enable

    echo "Restarting all services..."
    sudo systemctl restart nginx php${PHP_VERSION}-fpm mysql redis
    echo "Server setup complete!"
}

# Revert server setup
revert_server() {
    echo "Reverting server setup..."
    sudo systemctl stop nginx php${PHP_VERSION}-fpm mysql redis
    sudo systemctl disable nginx php${PHP_VERSION}-fpm mysql redis
    sudo apt purge -y nginx php-cli php-fpm mysql-server redis phpmyadmin nodejs
    sudo rm -f /usr/local/bin/composer
    echo "Server setup reverted."
}

# Function to set up Nginx configuration
setup_nginx() {
    if [ -f "$DOMAIN_CONF" ]; then
        handle_existing_step "Nginx configuration for ${DOMAIN_NAME}"
        if [ $? -eq 0 ]; then
            echo "Overwriting Nginx configuration..."
            sudo rm -f "$DOMAIN_CONF"
        else
            echo "Skipping Nginx setup and continuing."
            return
        fi
    fi

    echo "Creating Nginx configuration for ${DOMAIN_NAME}..."
    sudo bash -c "cat > $DOMAIN_CONF" <<EOL
server {
    listen 80;
    server_name ${DOMAIN_NAME};

    root ${PROJECT_PATH}/public;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location /phpmyadmin {
        root /usr/share/;
        index index.php;
        location ~ ^/phpmyadmin/(.+\.php)$ {
            try_files \$uri =404;
            fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            include fastcgi_params;
        }
        location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
            root /usr/share/;
        }
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL
    echo "Nginx configuration created."

    # Enable site
    if [ -L "/etc/nginx/sites-enabled/${DOMAIN_NAME}" ]; then
        echo "Symbolic link for ${DOMAIN_NAME} already exists. Skipping."
    else
        echo "Enabling site ${DOMAIN_NAME}..."
        sudo ln -sf "$DOMAIN_CONF" /etc/nginx/sites-enabled/
    fi

    # Add domain to /etc/hosts
    if ! grep -q "$DOMAIN_NAME" /etc/hosts; then
        echo "Adding ${DOMAIN_NAME} to /etc/hosts..."
        echo "127.0.0.1 ${DOMAIN_NAME}" | sudo tee -a /etc/hosts > /dev/null
        echo "Domain added to /etc/hosts."
    else
        echo "${DOMAIN_NAME} already exists in /etc/hosts. Skipping."
    fi

    # Restart Nginx
    echo "Restarting Nginx..."
    sudo systemctl restart nginx
    echo "Nginx restarted."
}

# Revert Nginx setup
revert_nginx() {
    echo "Reverting Nginx configuration..."
    sudo rm -f "$DOMAIN_CONF"
    sudo rm -f "/etc/nginx/sites-enabled/${DOMAIN_NAME}"
    sudo sed -i "/127.0.0.1 ${DOMAIN_NAME}/d" /etc/hosts
    sudo systemctl reload nginx
    echo "Nginx configuration reverted."
}

# Function to check SSH access
check_ssh_access() {
    echo "Checking SSH access to GitHub..."
    ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"
    if [ $? -ne 0 ]; then
        echo "Error: SSH access to GitHub failed. Please ensure your SSH key is added to GitHub."
        exit 1
    fi
    echo "SSH access to GitHub verified."
}

# Function to perform Git operations
setup_git() {
    cd "$PROJECT_PATH" || exit

    if [ -d ".git" ]; then
        echo "Git is already initialized in $PROJECT_PATH."
    else
        echo "Initializing Git repository..."
        git init
        git remote add origin "$REPO_URL"
    fi

    echo "Would you like to pull changes from the repository or push your current changes?"
    read -p "Enter 'pull' or 'push' (default: skip): " GIT_ACTION

    case $GIT_ACTION in
        pull)
            echo "Pulling changes from the repository (hard reset)..."
            git fetch origin
            git reset --hard origin/$(git symbolic-ref --short HEAD) || {
                echo "Failed to pull changes. Please check your remote setup."
                exit 1
            }
            echo "Pulled changes successfully. Local directory is now in sync with the remote."
            ;;
        push)
            echo "Pushing changes to the repository (hard reset on remote)..."
            git add .
            git commit -m "Hard reset remote with local changes" || echo "No changes to commit."
            git push --force || {
                echo "Failed to push changes. Please check your remote setup."
                exit 1
            }
            echo "Changes pushed successfully. Remote repository is now in sync with the local directory."
            ;;
        *)
            echo "Skipping Git operations."
            ;;
    esac
}


# Function to display MySQL credentials after setup
echo_credentials() {
    echo "================================================="
    echo "MySQL Credentials:"
    echo "User: root"
    echo "Password: $MYSQL_ROOT_PASSWORD"
    echo "================================================="
}

# Menu for selecting steps
menu() {
    echo "Select an option:"
    echo "1) Run All Steps"
    echo "2) Setup Laravel Project"
    echo "3) Setup Server"
    echo "4) Setup Nginx"
    echo "5) Perform Git Operations"
    echo "6) Revert Laravel Project"
    echo "7) Revert Server Setup"
    echo "8) Revert Nginx Setup"
    echo "9) Revert Git Setup"
    echo "10) Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1) setup_server; setup_laravel; setup_nginx; echo_credentials; read -p "Do you want to run Git setup? (y/n): " RUN_GIT; [[ "$RUN_GIT" == "y" ]] && setup_git ;;
        2) setup_laravel ;;
        3) setup_server ;;
        4) setup_nginx ;;
        5) echo_credentials; setup_git ;;
        6) revert_laravel ;;
        7) revert_server ;;
        8) revert_nginx ;;
        9) revert_git ;;
        10) exit 0 ;;
        *) echo "Invalid choice. Exiting."; exit 1 ;;
    esac
}

# Display the menu
while true; do
    menu
done

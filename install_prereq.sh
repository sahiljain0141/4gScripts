#!/bin/bash

# Function to install Paramiko
install_paramiko() {
    echo "Installing Paramiko..."
    sudo apt update
    sudo apt install -y python3-paramiko
}

# Function to install sshpass
install_sshpass() {
    echo "Installing sshpass..."
    sudo apt update
    sudo apt install -y sshpass
}

# Function to install Python 3
install_python3() {
    echo "Installing Python 3..."
    sudo apt update
    sudo apt install -y python3
}

# Check if Paramiko is installed
if ! python3 -c "import paramiko" &> /dev/null; then
    install_paramiko
fi

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    install_sshpass
fi

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    install_python3
fi

# Check if all dependencies are installed
if python3 -c "import paramiko" &> /dev/null && command -v sshpass &> /dev/null && command -v python3 &> /dev/null; then
    echo "All dependencies are now installed."
fi


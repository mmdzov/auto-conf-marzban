#!/bin/bash

# Ask for username
read -e -p "Please enter your username: " -i "admin" username

# Ask for password
read -e -p "Please enter your password: " -i "admin" password

marzban cli admin create --sudo
echo $username
echo $password
echo $password
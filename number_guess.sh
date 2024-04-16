#!/bin/bash
validate_username() {
    # Check if username length is less than or equal to 22 characters
    if [ ${#username} -le 22 ]; then
        return 0
    else
        return 1
    fi
}

# Function to check if a username exists in the database
username_exists() {
    if grep -q "^$1:" database.txt; then
        return 0
    else
        return 1
    fi
}

# Function to get game statistics for a user
get_game_stats() {
    local user=$1
    local stats=$(grep "^$user:" database.txt | cut -d: -f2)
    games_played=$(echo "$stats" | cut -d, -f1)
    best_game=$(echo "$stats" | cut -d, -f2)
}

# Function to update game statistics for a user
update_game_stats() {
    local user=$1
    local attempts=$2

    if ! username_exists $user; then
        echo "$user:1,$attempts" >> database.txt
    else
        get_game_stats $user
        ((games_played++))
        if [ $attempts -lt $best_game ] || [ $best_game -eq 0 ]; then
            best_game=$attempts
        fi
        sed -i "s/^$user:.*/$user:$games_played,$best_game/" database.txt
    fi
}

# Generate a random number between 1 and 100
secret_number=$(( ( RANDOM % 1000 ) + 1 ))
attempts=0
guessed_number=-1

echo "Welcome to the Number Guessing Game!"
echo "I've picked a number between 1 and 1000. Can you guess it?"

# Prompt the user for a username and validate its length
while true; do
    read -p "Enter your username (up to 22 characters): " username
    validate_username
    if [ $? -eq 0 ]; then
        break
    else
        echo "Username must be up to 22 characters. Please try again."
    fi
done

# Check if the username exists in the database
if username_exists $username; then
    get_game_stats $username
    echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
else
    echo "Welcome, $username! It looks like this is your first time here."
fi

echo "Guess the secret number between 1 and 1000:"

# Loop until the user guesses the correct number
while [ $guessed_number -ne $secret_number ]; do
    read -p "Enter your guess: " guessed_number
    (( attempts++ ))

    # Check if the guess is correct, too high, or too low
    if [ $guessed_number -eq $secret_number ]; then
        echo "Congratulations, $username! You've guessed the number $secret_number correctly!"
        echo "It took you $attempts attempts."
        update_game_stats $username $attempts
    elif [ $guessed_number -lt $secret_number ]; then
        echo "Too low, $username! Try again."
    else
        echo "Too high, $username! Try again."
    fi
done
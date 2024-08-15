#!/bin/bash
PSQL="psql --username=postgres --dbname=number_guess -t --no-align -c"

function is_integer() {
    [[ "$1" =~ ^-?[0-9]+$ ]]
}
triesThisGame=0

random_number=$((RANDOM % 1001))
echo "Enter your username:"
read username
result=$($PSQL "SELECT * FROM users WHERE username='$username'")

IFS='|' read -r USER_ID USER_USERNAME USER_GAMES USER_BEST <<< "$result"

if [[ -z $USER_USERNAME ]]; then

    INSERT_USER=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$username', 0, 0) RETURNING id" | awk 'NR==1 {print $1}')

    if [[ -n $INSERT_USER ]]; then
        USER_ID=$INSERT_USER
        USER_GAMES=0
        USER_BEST=0
        echo "Welcome, $username! It looks like this is your first time here."
    else
        exit 1
    fi
else
    echo "Welcome back, $username! You have played $USER_GAMES games, and your best game took $USER_BEST guesses."

   #echo "Welcome back, $USER_USERNAME! You have played $USER_GAMES games, and your best game took $USER_BEST guesses."
fi
echo $random_number
while true; do
    echo "Guess the secret number between 1 and 1000: "
    read user_input
    if ! is_integer "$user_input"; then
        echo "That is not an integer, guess again: "
        continue
    fi
    ((triesThisGame++))
    if [ "$user_input" -eq "$random_number" ]; then
        if [ "$triesThisGame" -lt "$USER_BEST" ] || [ "$USER_BEST" -eq 0 ]; then
            updateBestGame=$($PSQL "UPDATE users SET best_game = $triesThisGame WHERE username='$username'")
        fi
        ((USER_GAMES++))
        updateGamesPlayed=$($PSQL "UPDATE users SET games_played = $USER_GAMES WHERE username='$username'")
        echo "You guessed it in $triesThisGame tries. The secret number was $user_input. Nice job!"
        exit
        break
    elif [ "$user_input" -lt "$random_number" ]; then
        echo "It's higher than that, guess again: "
    else
        echo "It's lower than that, guess again: "
    fi
done
 
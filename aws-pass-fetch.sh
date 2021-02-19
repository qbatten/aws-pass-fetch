#!/bin/sh
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
#
#
# 
# AWS-cli using an external process https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sourcing-external.html
# JSON from Bash https://stackoverflow.com/questions/12524437/output-json-from-bash-script/12524510



programname=$0

function usage {
    echo "$verbose"
cat <<-_EOF
Usage:
    
    Add to your ~/.aws/config file, one line under each profile. The 
    line to add is:
    """
    credential_process = $programname [aws_access_key_id] 
        [cmd_fetch_aws_secret_access_key] [session_token (optional)] 
        [expiration (optional)]
    """
    
Arguments:
    [aws_access_key_id]: Your access key (the actual key string, e.g. 
        what you'd put in  "aws_access_key_id = {...here..})"
    [cmd_fetch_aws_secret_access_key]: Whatever you'd type at the 
        commandline in order to fetch your secret key for this profile. 
        (e.g. if you'd call "pass aws/my_profile/secret_key" to get the
        aws_secret_access_key for this profile, this arg should be 
        "aws/my_profile/secret_key". If you were using a reuglar 
        credentials file, you'd have a line that said something like 
        "aws_secret_access_key = {your_secret_key}". This command should
        return *just* that secret key ("your_secret_key").
    [session_token]: (optional) If you'd put an aws_session_token in 
        your credentials file, include it here. It's relevant if you
        have temporary credentials.
    [expiration]: (optional) An ISO8601 timestamp of when these 
        credentials expire. It's relevant if you
        have temporary credentials.

Installation:
    1. Copy this somewhere on your drive and give it execution
       permission (e.g. chmod 700 ~/my_scripts/aws-pass-fetch.sh)
    2. Make sure you have a way to easily fetch your creds via the
       commandline. I use pass (https://www.passwordstore.org), but you
       can use any credential manager that lets you enter one command
       and get back your password as a string (see examples for more).
    3. Put a line in your ~/.aws/config or ~/.aws/credentials 
       file, under the relevant profile, as follows:
       """
       [my_profile]
       credential_process = /path/to/aws-pass-fetch.sh MYACCESSKEY 
            "PASSWDPROGRAM ARGTOFETCHSECRETKEY" (optional sesssion_token) 
            (optional expiration_time)
       """

Examples:
    [PERSON 1] 
        I'm using pass to store my secret key, under "aws_secret". 
        If I  wanted to see my secret key, I would run "pass aws_secret" 
        on the command line, and that command writes my secret key to 
        STDOUT (just the key itself, as a string). I'm using my default 
        profile and my access key is "AKIAYTXKXFACYMQOJNCF". My 
        credentials are permanent, so I wouldn't set a session_token in
        my normal credentials file. My aws-pass-fetch.sh file is at 
        "/User/Person1/.scripts/aws-pass-fetch.sh". My ~/.aws/config file has 
        this line under "[default]" (would be a single line):
        """
        credential_process = /User/Person1/.scripts/aws-pass-fetch.sh 
            AKIAYTXKXFACYMQOJNCF "pass aws_secret"
        """
    [PERSON 2] 
        I'm using Apple's Keychain Access to store my secret key,
        under "aws-personal" / "aws_secret_access_key". When I added this
        key to my keychain, I ran: "security add-generic-password 
        -a aws-personal -s aws-personal -l aws_secret_access_key 
        -w {my_secret_key}". I'm using my "work" profile and my access 
        key is "AKIAYTXPOIVCYMQOJNCF". My credentials are temporary, so 
        I normally do put my current session_token in my credentials file.
        I'll include that here, it's "AQoEXAMPLEH4aoAH0gNC" (NOTE: real 
        session_tokens are way longer than this example one). My creds
        last for 48 hours, so I'm not worried about auto-refreshing
        before they expire; I won't include an expiration timestamp. My 
        aws-pass-fetch.sh file is in my PATH. My ~/.aws/config file has this 
        line under "[work]" (would be a single line):
        """
        credential_process = aws-pass-fetch.sh AKIAYTXPOIVCYMQOJNCF "security
            find-generic-password -a aws-personal -s aws-personal -l 
            aws_secret_access_key" "AQoEXAMPLEH4aoAH0gNC"

        """

Context:
    (links work as of Feb 2021)
    - You can go to this AWS doc for more info about
      these credential file variables. Scroll down to "Global settings"
      and there's info about aws_access_key_id,  aws_secret_access_key,
      and aws_session_token. Link: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-global
    - You can go here for more on sourcing credentials with an external
      process. Link: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sourcing-external.html


_EOF
}

function args_to_json {
# 'usage: args_to_json key1 value1 key 2 value 2'
# ' e.g. $ echo key1 1 key2 2 key3 3 | args_to_json'
# '      {"key1":1, "key2":2, "key3":3}" '
# 'written by Jimilian https://stackoverflow.com/users/868947/jimilian'
    arr=();

    while read x y; 
    do 
        arr=("${arr[@]}" $x $y)
    done

    vars=(${arr[@]})
    len=${#arr[@]}

    printf "{"
    for (( i=0; i<len; i+=2 ))
    do
        printf "\"${vars[i]}\": ${vars[i+1]}"
        if [ $i -lt $((len-2)) ] ; then
            printf ", "
        fi
    done
    printf "}"
    echo
}


if [ $# -lt 2 ] ; then
    usage
    exit 1
elif [ $# -gt 4 ] ; then
    usage
    exit 1
fi

arr_args=($@)
arr_keys=("AccessKeyId" "SecretAccessKey" "SessionToken" "Expiration")
JSON_ARGS=' Version 1 '
JSON_ARGS+="${arr_keys[0]} \"$1\" "
JSON_ARGS+="${arr_keys[1]} \"`$2`\" "

if [ "$3" != "" ] ; then
    JSON_ARGS+="${arr_keys[2]} \"$3\" "
    if [ "$4" != "" ] ; then
        JSON_ARGS+="${arr_keys[3]} \"$3\" "
    fi
fi

echo "$JSON_ARGS" | args_to_json


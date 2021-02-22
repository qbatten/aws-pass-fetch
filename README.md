# AWS-CLI Password Fetcher

This is a lil script that automatically fetches your AWS secret keys from your password manager as needed.

It could be helpful to you if:
1. You want to keep your dotfiles clean of sensitive info, and
2. You switch AWS profiles frequently

## Installation

1. Copy aws-pass-fetch.sh to somewhere on your PATH, or wherever you keep random scripts (e.g. for me, that's ~/.scripts, so I'd download this file and put it there).
2. Give the script execution permission (e.g. in your terminal, run `chmod 700 /path/to/aws-pass-fetch.sh`)
3. Make sure you have an easy way to fetch your AWS creds via the commandline. I use Mac's Keychain Access, but you can use any credential manager that lets you enter one command and get back your password as a string (see examples for more).
4. Put a line in your ~/.aws/config or ~/.aws/credentials file, under the relevant profile, as follows:

```
[my_profile]
credential_process = /path/to/aws-pass-fetch.sh [aws_access_key] [call to password mgr, incl which password to return] [optional session_token] [optional expiration_time]
```

5. Note that if any of these args has spaces in it, you must put double quotes around that one (e.g. if my script is in "Super Fun Scripts," that has to be quoted... `"~/Super Fun Scripts/aws-pass-fetch.sh"`)
6. You may want to test it out by copying the above line, minus `credential_process = `, and running it in your terminal. It should return your password (and only your password) to STDOUT.
7. You should be good to go! Your credentials will automatically be pulled from your password manager whenever needed, no matter what profile you're using!

## Examples

#### Person 1

* I'm using [pass](https://www.passwordstore.org) to store my secret key, under the name "aws_secret". So, if I  wanted to see my secret key, I would run `pass aws_secret` on the command line, and that command writes my secret key to STDOUT (just the key itself, as a string). 
    * Because the above command has a space in it, I'll need to quote it in my credentials file. If the path to my script had spaces in it, that would need to be surrounded by quotes as well.
* I'm using my `default` AWS profile and my access key is "AKIAYTXKXFACYMQOJNCF". 
* My credentials are permanent, so I wouldn't set a session_token in my normal credentials file. 
* My aws-pass-fetch.sh file is at "/User/Person1/.scripts/aws-pass-fetch.sh". My ~/.aws/config file looks like this: 

```
[default]
credential_process = /User/Person1/.scripts/aws-pass-fetch.sh AKIAYTXKXFACYMQOJNCF "pass aws_secret"
```

#### Person 2 

* I'm using Apple's Keychain Access to store my secret keys.
* I'm using two profiles: 
    * [work], for which my access  key is "AKIAYTXPOIVCYMQOJNCF".
    * [default], for which my access  key is "AKFAYTVOLRHOCYMPVENW". 
, under "aws-personal" / "aws_secret_access_key". 
* When I added these secret keys to my keychain, I ran: `security add-generic-password  -a [my_account_username] -s [aws-default or aws-work] -l aws_secret_access_key  -w [my_secret_key]`. 
* My work credentials are temporary, so  I normally do put my current session_token in my credentials file. I'll include that here, it's "AQoEXAMPLEH4aoAH0gNC" (NOTE: real  session_tokens are way longer than this example one). 
* My work creds last for 48 hours, so I'm not worried about auto-refreshing before they expire; I won't include an expiration timestamp for them.
* My aws-pass-fetch.sh file is in my PATH. 
  
My ~/.aws/config file looks like this:

``` 
[default]
credential_process = aws-pass-fetch.sh AKFAYTVOLRHOCYMPVENW "security find-generic-password -a aws-personal -s aws-default -l aws_secret_access_key" 

[work]
credential_process = aws-pass-fetch.sh AKIAYTXPOIVCYMQOJNCF "security find-generic-password -a aws-personal -s aws-work -l aws_secret_access_key" AQoEXAMPLEH4aoAH0gNC
```


## Other Thoughts and Useful Links

* I like using Keychain Access and giving my user ownership of the key. That way, I never have to enter my password when AWS calls this script. Of course, if you need these keys to be secret from other people who can access your computer, or if they're super-important, you might want to not do that. Pass will prompt you quite frequently to re-unlock your pass database (unless you set it to stay open for longer).
* More on using Keychain Access from the CLI [link](https://www.netmeister.org/blog/keychain-passwords.html).
* [This AWS doc](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-global) has more info about these credential file variables. Scroll down to "Global settings" and there's info about aws_access_key_id,  aws_secret_access_key, and aws_session_token. 
* [This AWS doc](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sourcing-external.html) has more on sourcing credentials with an external process.

## Acknowledgements

The "JSON from Bash" function is based on [this StackOverflow answer](https://stackoverflow.com/questions/12524437/output-json-from-bash-script/12524510) by Jimilian. 

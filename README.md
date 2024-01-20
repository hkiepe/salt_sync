# salt_sync

The script is created to synchronize git repositories to a remote computer and. It collects all data to be syncronized and syncs it to the remote computer and copies all the files to the appropriate folders by running a script on the remote machine as sudo user. The enter the password the script uses a gpg password hash.

## create a password hash

To run the remote script, the script needs to pass the sudo password of the remote user.

To make it safe the script uses the encrypted password hash specified in the settings file.

Here is how to encrypt the password on your local machine.

## Install gpg and create the hash

Dependent of your local linux system you need to install gpg.

```sh
sudo apt install gnupg
```

Then you have to create your own keypair. Run the below command and follow the instructions. Choose to create a keypair without passphrase.

```sh
gpg --full-generate-key
```

Now you can list the keys:

```sh
gpg --list-keys --quiet
```

Now create a temporary file with the remote sudo password in it. Lets say a file called password.txt.
DONT FORGET TO DELETE THIS FILE AFTER YOU HAVE CREATED THE HASH.

```sh
vim ./password.txt
```

Create the hash using the KEY_ID from the key list. The command will create a file called hashed_password.gpg

```sh
gpg --encrypt --sign --armor --recipient KEY_ID --output hashed_password.gpg ./password.txt
```

After creating the hash please delete the password.txt file permanently from your computer for security reasons.
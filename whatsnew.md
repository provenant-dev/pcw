## 7 Feb 2023

* Renamed some commands to make their names shorter and clearer (e.g., "credential" --> "cred", "legal-entity" --> "le").
* Fixed the S3 functionality (and added upgrader 4 to guarantee correct config for it in all wallets).
* Modified issue-* and join-* scripts so they use the S3 functionality correctly.
* Added new commands, test-s3-upload and test-s3-download, to let people confirm S3 is currently working for them.
* Improved the unlock command so it doesn't prompt unless needed.
* Added a new command, lock, which does the opposite of unlock.
* Added warnings to the scripts used to issue ECRs as QVIs, explaining that this is unusual and there's a simpler approach.
* Polished the generate-challenge and generate-challenge-as scripts a bit.
* Allowed upgrade scripts to write to stderr and thus generate messages to users. Used this in upgrader 4 to warn user to source .bashrc.

## 3 Feb 2023

* Fixed a number of bugs in scripts and configuration. Nothing huge, but a few gotchas removed. 
* Wallets now report which EC2 instance they are, which will make it easier for sysadmins in AWS to make sure they're working on the same wallets that a person is talking to over ssh. (You can manually run a new command for this if you like: describe-wallet-on-ec2)
* Wallets now know whether they're connected to Provenant's AWS bill or are being hosted by one of our customers.
* All wallets should now have the S3 variables defined. If you wrote dummy values for these, please delete the exports from your .bashrc and log in again; you shouldn't be prompted again. I believe this means the new share-via-s3 command (called to share le.json, ecr.json, oor.json, etc.) will work for everyone.
* Wallets now have a generic upgrade mechanism that allows me to deploy new code and be reasonbly confident that old wallets transition into the right state to use the new code. Before, we were getting stuck periodically because code would be new and an old wallet had some kind of a weird state that prevented it from running. I believe this will make it more likely that customer wallets will be healthy and not generate support calls as we release new updates.
* There's no longer any reason to have a custom version of xar/source.sh, so that file should automatically be changed to the standard, checked-in version from git on every wallet.
* I added a .gitignore for ~/xar/data. Combined with previous change, this should mean that if you run git status inside ~/xar, it should be clean; no more long list of files that are out of sync.
* You can now run the watch command to sync your wallet with witnesses, instead of a longer and less convenient syntax.
* If you are using wallets in dev or stage (instead of production), the wallets now automatically use a hardcoded password to lower developer friction and passwords you have to remember.
* Wallets hosted by Provenant now shut down automatically after 30 minutes of having no active ssh session. Combined with a previous setting that automatically terminates idle ssh sessions after a while, this means that (unless you set up something like Ruth's config, to enable keep-alives in the ssh client), if you leave your ssh window idle in a connection to the browser, the ssh connection should drop after a while. Half an hour after that, the machine should automatically power down, saving us on our amazon bill and decreasing the attack surface for hackers. IMPORTANT: this means that Daniel is no longer in the business of starting and stopping wallets for you -- it has become self-service. If you want to shut down a wallet yourself, from inside it, just run the command sudo poweroff instead of saying exit. But even if you just exit, the machine should shut down reasonably soon. If you want to start your machine, just load the following URL in your browser: https://start.wallet.provenant.net/yourfirstname@provenant.net. 
* Added some additional protections to make maintain --reset less likely to be used wrong.
* The repo that used to be named https://github.com/provenant-dev/vlei-qvi has been renamed to xar, and its readme has been updated. Although it is still technically a fork of https://github.com/GLEIF-IT/vlei-qvi, I don't expect us to push PRs there as a general rule; we are diverging from GLEIF's code (though we can still pick up bug fixes from them if we manually do so). The main, dev, and v1.0 branches are all in sync. At this point, I plan to freeze v1.0. Our wallets should be on main, and dev is where I'll do experiments.
* Created a new base image for wallets, which has many weeks worth of additional security fixes and bug fixes. If we give our customers a wallet image, we should use this new one, which is called "pcw-base-15".
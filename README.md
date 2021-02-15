# Paul's Boostraps

### git-secrets

* Used to protect credentials and secrets from being accidentally pushed to a repo
* To use, install using provided shell script and then run `git-secrets --install` (creates 3 git hooks to automate running of scan) in desired git folder
* Can also use `git-secrets --scan` for a manual scan of credentials

### BFG Repo Cleaner

* https://github.com/rtyley/bfg-repo-cleaner
* Used to clean a repo of any unwanted files in history (but always consider any sensitive data pushed to a public repo as leaked, hence deactivate things like API keys asap)
* Usage guide:
  * `bfg --delete-files` [FILE_NAME]
  * `git reflog expire --expire=now --all && git gc --prune=now --aggressive`
  * `git push [REMOTE_NAME] --force`

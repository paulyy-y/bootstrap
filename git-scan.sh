# Use git-secrets binary in order to protect any new git repos from accidental secret pushes
git clone https://github.com/awslabs/git-secrets.git ~/
cd git-secrets
sudo make install

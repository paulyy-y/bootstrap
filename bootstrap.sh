mkdir ~/bootstrap/

# Git-secrets
git clone https://github.com/awslabs/git-secrets.git ~/bootstrap/git-secrets
sudo make install -C ~/bootstrap/git-secrets
rm -r ~/bootstrap/git-secrets

# BFG Repo Cleaner
wget https://repo1.maven.org/maven2/com/madgag/bfg/1.13.2/bfg-1.13.2.jar -O ~/bootstrap/bfg.jar
echo "alias bfg='java -jar ~/bootstrap/bfg.jar'" >> ~/.bashrc
source ~/.bashrc

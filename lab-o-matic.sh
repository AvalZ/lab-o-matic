#!/usr/bin/env bash

# lab-o-matic is a script to automagically retrieve WordPress latest version
# creating 3 different blog configurations:
#   * a blog
#   * a company/freelance portfolio
#   * an e-commerce
#
# This script is part of Owasp Italy "Stand by Wordpress" project
#
# (C) Owasp Italy - <thesp0nge@owasp.org>

# Changelog
# v0.00 - 20150603 - Let's start

##############################################################################
# Let's the story begins
##############################################################################

# CONSTANTS
VERSION="0.00"
CURL=`which curl`
MYSQL=`which mysql`
PHP=`which php`

WP_VERSION="4.2.2"
WP_VERSION_CHECK_URL="http://api.wordpress.org/core/version-check/1.0/?version=$WP_VERSION"
WP_LATEST="https://wordpress.org/latest.zip"
WP_PLUGIN_PREFIX="https://wordpress.org/plugins/"
WP_CLI_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
WP_CLI="/usr/local/bin/wp"

DOCUMENT_ROOT="$HOME/stand_by_wordpress/wordpress"
BLOG_ROOT=$DOCUMENT_ROOT/blog
PORTFOLIO_ROOT=$DOCUMENT_ROOT/portfolio
ECOMMERCE_ROOT=$DOCUMENT_ROOT/ecommerce

create_document_root_tree() {
  if ! [ -x $DOCUMENT_ROOT ]; then
    echo "Creating $DOCUMENT_ROOT"
    mkdir -p $DOCUMENT_ROOT
  fi
}
install_wp_cli(){
  $CURL -O $WP_CLI_URL
  chmod +x wp-cli.phar
  sudo mv wp-cli.phar $WP_CLI
  ls -l $WP_CLI
}
download_wordpress_core(){
  $WP_CLI core download --path=$DOCUMENT_ROOT/wp
}
clone_wordpress_core(){
  cp -a $DOCUMENT_ROOT/wp $BLOG_ROOT
  cp -a $DOCUMENT_ROOT/wp $PORTFOLIO_ROOT
  cp -a $DOCUMENT_ROOT/wp $ECOMMERCE_ROOT
}
create_wordpress_configurations(){
  $WP_CLI core config --path=$BLOG_ROOT      --dbname=blog --dbuser=blog_user --dbpass=blog_password
  $WP_CLI core config --path=$PORTFOLIO_ROOT --dbname=portfolio --dbuser=portfolio_user --dbpass=portfolio_password
  $WP_CLI core config --path=$ECOMMERCE_ROOT --dbname=ecommerce --dbuser=ecommerce_user --dbpass=ecommerce_password
}
create_mysql_users(){
  $MYSQL -u root -p < create_users.sql
}

install_wordpress_sites(){
  $WP_CLI core install --path=$BLOG_ROOT      --url=http://localhost:8000 --title="Stand by WordPress lab blog"       --admin_user=admin --admin_password=admin_pwd --admin_email=admin@localhost.it
  $WP_CLI core install --path=$PORTFOLIO_ROOT --url=http://localhost:8001 --title="Stand by WordPress lab portfolio"  --admin_user=admin --admin_password=admin_pwd --admin_email=admin@localhost.it
  $WP_CLI core install --path=$ECOMMERCE_ROOT --url=http://localhost:8002 --title="Stand by WordPress lab ecommerce"  --admin_user=admin --admin_password=admin_pwd --admin_email=admin@localhost.it

	cp router.php $BLOT_ROOT/router.php
	cp router.php $PORTFOLIO_ROOT/router.php
	cp router.php $ECOMMERCE_ROOT/router.php
	

}

start_wordpress_sites(){
	php -S localhost:8000 -t $BLOG_ROOT $BLOG_ROOT/router.php &
	php -S localhost:8001 -t $PORTFOLIO_ROOT $PORTFOLIO_ROOT/router.php &
	php -S localhost:8002 -t $ECOMMERCE_ROOT $ECOMMERCE_ROOT/router.php &
}
args=`getopt vh: $*`
if [ $? != 0 ]
then
  echo 'an usage help message must be given'
  exit 2
fi

for i
do
  case "$i"
  in
    -v)
      echo $VERSION
      exit 0;;
    -a|-b)
      echo flag $i set; sflags="${i#-}$sflags";
      shift;;
    -o)
      echo oarg is "'"$2"'"; oarg="$2"; shift;
      shift;;
    --)
      shift; break;;
  esac
done

echo "[*] lab-o-matic v$VERSION"
echo "[*] Asking for sudo"
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
echo "[*] Creating stuff under $DOCUMENT_ROOT"
create_document_root_tree
echo "[*] Check if wp-cli.phar it has been installed"
if [ -e $WP_CLI ]; then
  echo "[+] Yes. Skipping install"
else
  echo "[!] No. Installing wp-cli.phar"
  install_wp_cli
  echo "[*] Installed $WP_CLI"
fi
echo "[*] Downloading WordPress core"
download_wordpress_core
echo "[*] Cloning WordPress core into target dirs"
clone_wordpress_core
echo "[*] Creating MySQL users"
create_mysql_users
echo "[*] Installing WordPress sites into database"
create_wordpress_configurations
install_wordpress_sites
echo "[*] Starting Wordpress sites"
start_wordpress_sites

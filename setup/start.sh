#!/bin/bash
if [ -f "/data/installed" ]; 
then
	echo "osTicket is already installed, please backup your work then delete /src/installed to re-run installer"
else 
	echo "We need to download & install osTicket. If this fails, make sure docker-compose has the version you want set.
	Downloading osTicket v${OSTICKET_VERSION} (If this shits the bed, make sure your line-endings are set to Unix)"
	cd /data 
	if [ -d "osticket" ]; 
	then 
		echo "osTicket might already be installed, checking out the version you specified."; 
		cd osticket 
		git checkout -b v${OSTICKET_VERSION} 
	else
		git clone --progress -b v${OSTICKET_VERSION} --depth 1 https://github.com/osTicket/osTicket.git osticket 
		cd osticket || echo "Failed to fetch osTicket, bailing.." && exit 2; 
    fi
# We want a custom error_reporting level for the installer.. because we aren't going to fix these now. 
    LEVEL=$(php -r 'echo E_ERROR | E_PARSE; ')
    echo "Deploying osTicket into upload." 
    php -d "error_reporting=$LEVEL" manage.php deploy -sv /data/upload 
    chown -R www-data:www-data /data/upload 
    mv /data/upload/setup /data/upload/setup_hidden 
    chown -R root:root /data/upload/setup_hidden 
    chmod -R go= /data/upload/setup_hidden 
    cd 
    date > /data/installed 

    php -d "error_reporting=$LEVEL" /setup/install.php 
fi; 
echo "Applying configuration file permissions." 
chmod 644 /data/upload/include/ost-config.php 

echo "If you haven't already, you can use /src/upload/include/plugins and start cloning your plugin repos into it for development.
Starting Apache2... login here: http://localhost:8080 username & password as per docker-compose config. To view email, open http://locahost:8025"

apache2-foreground
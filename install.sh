#!/usr/bin/bash

function download()
{
    sudo apt-get update
    while read line; do
		sudo apt-get install $line -y; 
    done < packages.txt

}

echo "Starting installation of the FirmAFL packages......this could take some time."
download
echo -e "Starting installation of FirmAE";
cd FirmAE
./install.sh
cd ..
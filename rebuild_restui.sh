DOMAIN=$1

# The steps are:
# - build the docker image
sudo docker build -t restui:latest https://github.com/Datawheel/mondrian-rest-ui.git#master
# - run the image in a temporary container and save the build in a volume
#  (the datachile_hddrestui volume will be handled later by docker-compose, update it if needed)
sudo docker run --rm --volume datachile_hddrestui:/app/src/build -e "REACT_APP_API_URL=https://chilecube.$DOMAIN" restui
# - delete the docker image
sudo docker rmi restui

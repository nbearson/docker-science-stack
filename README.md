# docker-science-stack
Docker cheatsheet:
```bash
# Run the image, get a shell
docker run -t -i nbearson/docker-science-stack /bin/bash
# Run the image, get a shell, and mount the current directory as /workspace
docker run -it --rm -v "$PWD":/workspace -w /workspace nbearson/docker-science-stack /bin/bash

# Build the image from just the Dockerfile
docker build -t nbearson/docker-science-stack .
# Push the built image to Dockerhub
docker push nbearson/docker-science-stack
```

# What's In The Box?

* HDF4 `$HDF4`
* HDF5 `$HDF5`
* netCDF `$NETCDF`
* NCO utilities
* Python 2.7
  * uwglance
  * pyhdf
  * netcdf4-python


# Why?

* I want to try out an a new version of GCC without having to worry about properly isolating it from the rest of my machine and deleting it later.
* I'm on a mac and want to compile code for a linux machine without dedicating idle resources to a VM.
* Once someone has done the work of putting together a docker image with everything you need (and we rarely need something too special), you can get a copy and use it with 1 terminal command.
* *Why not?*

For gcc only without the frills:

https://hub.docker.com/_/gcc/  
https://github.com/docker-library/gcc  

This is a debian-based image, but it comes with gcc (and now gfortran!) preinstalled and nothing else. Nice for getting a compiler for free to put through the paces.

# This image creates a common scientific build environment that includes:
# gfortran, hdf4, hdf5, netcdf4

# NOTE: nbearson/gfortran is a modified version of the official
# docker gcc image that includes gfortran. Now that the official
# image also includes gfortran, this line should change once a new build
# of the gcc image is pushed to dockerhub.
# to...
# FROM gcc
FROM nbearson/gfortran

ENV ZLIB_VERSION 1.2.8
ENV JPEG_VERSION 6b
ENV SZIP_VERSION 2.1
ENV HDF4_VERSION 4.2.12
ENV HDF5_VERSION 1.8.17
ENV NC4F_VERSION 4.4.4
ENV NC4C_VERSION 4.4.1 

# grab some packages we need
RUN apt-get update && apt-get install -y byacc bison diffutils flex make

# grab some convenience packages for using it as a build "machine"
RUN apt-get install -y vim

# get ready to build things
RUN mkdir -p /usr/man/man1
RUN mkdir /build

# perform downloads first so they get cached during development; does it make any difference afterwards?
RUN cd /build && curl -O http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz
RUN cd /build && curl -O https://www.hdfgroup.org/ftp/lib-external/jpeg/src/jpegsrc.v${JPEG_VERSION}.tar.gz
RUN cd /build && curl -O https://www.hdfgroup.org/ftp/lib-external/szip/${SZIP_VERSION}/src/szip-${SZIP_VERSION}.tar.gz
RUN cd /build && curl -O http://www.hdfgroup.org/ftp/HDF/releases/HDF${HDF4_VERSION}/src/hdf-${HDF4_VERSION}.tar.gz
RUN cd /build && curl -O http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-${HDF5_VERSION}.tar.gz
RUN cd /build && curl -O ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-${NC4C_VERSION}.tar.gz
RUN cd /build && curl -O ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-fortran-${NC4F_VERSION}.tar.gz

# add zlib
RUN cd /build && tar xzf zlib-${ZLIB_VERSION}.tar.gz && \
    cd zlib-${ZLIB_VERSION} && \
    ./configure --prefix="/usr" && make -j4 && make install

# add libjpeg
RUN cd /build && tar xzf jpegsrc.v${JPEG_VERSION}.tar.gz && \
    cd jpeg-${JPEG_VERSION} && \
    ./configure --prefix="/usr" && make -j4 && make install

## add szip
#RUN cd /build && tar zxf szip-${SZIP_VERSION}.tar.gz && \
#    cd szip-${SZIP_VERSION} && \
#    ./configure --prefix="/usr" --disable-shared --with-pic && make -j4 && make install

# FIXME: HDF4 currently claims it cannot build shared libraries for fortran? wtf?
# https://lists.hdfgroup.org/pipermail/hdf-forum_lists.hdfgroup.org/2016-January/009163.html
# enable-shared => disable-shared everywhere for now since we're most likely building static binaries anyways

# add hdf4
RUN cd /build && tar xzf hdf-${HDF4_VERSION}.tar.gz && \
    cd hdf-${HDF4_VERSION} && \
    ./configure --prefix="/usr" --disable-netcdf --enable-fortran --disable-shared --with-zlib="/usr" --with-jpeg="/usr" && make -j4 && make install

# add hdf5
RUN cd /build && tar xzf hdf5-${HDF5_VERSION}.tar.gz && \
    cd hdf5-${HDF5_VERSION} && \
    ./configure --prefix="/usr" --disable-shared --with-pic --with-zlib="/usr" --enable-cxx --enable-fortran --enable-fortran2003 --with-pthread && make -j4 && make install

# add netcdf-c
RUN cd /build && tar xzf netcdf-${NC4C_VERSION}.tar.gz && \
    cd netcdf-${NC4C_VERSION} && \
    CPPFLAGS="-I/usr/include -I/usr/lib/x86_64-linux-gnu" \
    LDFLAGS="-L/usr/lib -L/usr/lib/x86_64-linux-gnu" \
    LD_LIBRARY_PATH=/usr/lib:/usr/lib/x86_64-linux-gnu \
    LIBS="-ldf -lhdf5_hl -lhdf5 -ljpeg -ldl -lm -lz" \
    ./configure --prefix="/usr" --enable-hdf4 --disable-dap --disable-shared --with-pic  && make -j4 && make install

# add netcdf-fortran
# compiling against this requires -lnetcdff (note the extra f)
RUN cd /build && tar xzf netcdf-fortran-${NC4F_VERSION}.tar.gz && \
    cd netcdf-fortran-${NC4F_VERSION} && \
    CPPFLAGS="-I/usr/include -I/usr/lib/x86_64-linux-gnu" \
    LDFLAGS="-L/usr/lib -L/usr/lib/x86_64-linux-gnu" \
    LD_LIBRARY_PATH=/usr/lib:/usr/lib/x86_64-linux-gnu \
    LIBS="-lnetcdf -ldf -lhdf5_hl -lhdf5 -ljpeg -ldl -lm -lz" \
    ./configure --prefix="/usr" --disable-dap --disable-shared --with-pic && make -j4 && make install

# remove all the build cruft
RUN rm -rf /build
RUN rm -rf /usr/man

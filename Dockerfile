# This image creates a common scientific build environment that includes:
# gfortran, hdf4, hdf5, netcdf4
FROM nbearson/gfortran

ENV ZLIB_VERSION 1.2.8
ENV JPEG_VERSION 6b
ENV SZIP_VERSION 2.1
ENV HDF4_VERSION 4.2.12
ENV HDF5_VERSION 1.8.17
ENV NETCDF4_VERSION 4.4.1 

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
RUN cd /build && curl -O ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-${NETCDF4_VERSION}.tar.gz


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

# FIXME: CFLAGS & CXXFLAGS - do we need to unset?

# add hdf5
RUN cd /build && tar xzf hdf5-${HDF5_VERSION}.tar.gz && \
    cd hdf5-${HDF5_VERSION} && \
    ./configure --prefix="/usr" --disable-shared --with-pic --with-zlib="/usr" --enable-cxx --enable-fortran --enable-fortran2003 --with-pthread && make -j4 && make install

# add netcdf
# FIXME: failing with...
# configure: error: Can't find or link to the hdf5 library. Use --disable-netcdf-4, or see config.log for errors.
# but we don't need it for clavrx so skip for now
#
#RUN cd /build && tar xzf netcdf-${NETCDF4_VERSION}.tar.gz && \
#    cd netcdf-${NETCDF4_VERSION} && \
#    ./configure --prefix="/usr" --enable-hdf4 --enable-hdf4-file-tests --enable-fortran --disable-shared --disable-doxygen --disable-dap --with-pic  && make -j4 && make install


# remove all the build cruft
#RUN rm -rf /build
#RUN rm -rf /usr/man

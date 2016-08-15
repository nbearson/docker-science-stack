# This image creates a common scientific build environment that includes:
# gfortran, hdf4, hdf5, netcdf4

FROM gcc:latest

ENV ZLIB_VERSION 1.2.8
ENV JPEG_VERSION 6b
ENV SZIP_VERSION 2.1
ENV HDF4_VERSION 4.2.12
# for pre-libdl dependency:
#ENV HDF5_VERSION 1.8.10-patch1
ENV HDF5_VERSION 1.8.17
ENV NC4F_VERSION 4.4.4
ENV NC4C_VERSION 4.4.1

# grab some packages we need
RUN apt-get update && apt-get install -y byacc bison diffutils flex make

# grab some convenience packages for using it as a build "machine"
RUN apt-get install -y vim

# this is our install dir for everything non-core
RUN mkdir -p /opt

# add zlib
#RUN apt-get install -y zlib-devel
RUN mkdir -p /build && cd /build && \
    curl -O http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz && \
    tar xzf zlib-${ZLIB_VERSION}.tar.gz && \
    cd zlib-${ZLIB_VERSION} && \
    ./configure && make -j4 && make install && \
    cp configure.log /opt/config.log-zlib-${ZLIB_VERSION} && \
    rm -rf /build

# add libjpeg
#RUN apt-get install -y jpeg-devel
RUN mkdir -p /build && cd /build && \
    curl -O https://www.hdfgroup.org/ftp/lib-external/jpeg/src/jpegsrc.v${JPEG_VERSION}.tar.gz && \
    tar xzf jpegsrc.v${JPEG_VERSION}.tar.gz && \
    cd jpeg-${JPEG_VERSION} && \
    ./configure && make -j4 && make install && \
    cp config.log /opt/config.log-jpeg-${JPEG_VERSION} && \
    rm -rf /build

## add szip
#RUN mkdir -p /build && cd /build && curl -O https://www.hdfgroup.org/ftp/lib-external/szip/${SZIP_VERSION}/src/szip-${SZIP_VERSION}.tar.gz && \
#    tar zxf szip-${SZIP_VERSION}.tar.gz && \
#    cd szip-${SZIP_VERSION} && \
#    ./configure --prefix="/usr" --disable-shared --with-pic && make -j4 && make install && \
#    cp config.log /config/config.log-szip-${SZIP_VERSION} && \
#    rm -rf /build

# add hdf4
RUN mkdir -p /build /opt/hdf4 && cd /build && \
    curl -O http://www.hdfgroup.org/ftp/HDF/releases/HDF${HDF4_VERSION}/src/hdf-${HDF4_VERSION}.tar.gz && \
    tar xzf hdf-${HDF4_VERSION}.tar.gz && \
    cd hdf-${HDF4_VERSION} && \
    CFLAGS="-fPIC -DHAVE_NETCDF -fno-strict-aliasing" \
    CXXFLAGS="-fPIC -DHAVE_NETCDF -fno-strict-aliasing" \
    ./configure --prefix="/opt/hdf4" --disable-netcdf --enable-fortran && make -j4 && make install && \
    cp config.log /opt/hdf4/config.log-hdf4-${HDF4_VERSION} && \
    rm -rf /build

# add hdf5
# note - hdf5 post-1.8.11 now includes -ldl as a dependency
# http://hdf-forum.184993.n3.nabble.com/Errors-compiling-against-Static-build-HDF5-1-8-11-Need-for-ldl-added-to-linker-arguments-td4026300.html
RUN mkdir -p /build /opt/hdf5 && cd /build && \
    curl -O https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.gz && \
    tar xzf hdf5-${HDF5_VERSION}.tar.gz && \
    cd hdf5-${HDF5_VERSION} && \
    ./configure --prefix="/opt/hdf5" --with-pic --with-zlib="/opt/zlib" --enable-cxx --enable-fortran --enable-fortran2003 --with-pthread && make -j4 && make install && \
    cp config.log /opt/hdf5/config.log-hdf5-${HDF5_VERSION} && \
    rm -rf /build

# add netcdf-c
RUN mkdir -p /build /opt/netcdf4 && cd /build && \
    curl -O ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-${NC4C_VERSION}.tar.gz && \
    tar xzf netcdf-${NC4C_VERSION}.tar.gz && \
    cd netcdf-${NC4C_VERSION} && \
    CPPFLAGS="-I/opt/hdf4/include -I/opt/hdf5/include" \
    LDFLAGS="-L/opt/hdf4/lib -L/opt/hdf5/lib" \
    LD_LIBRARY_PATH="/opt/zlib/lib:/opt/jpeg/lib:/opt/hdf4/lib:/opt/hdf5/lib" \
    LIBS="-ldf -lhdf5_hl -lhdf5 -ljpeg -lm -lz" \
    ./configure --prefix="/opt/netcdf4" --enable-hdf4 --disable-dap --with-pic  && make -j4 && make install && \
    cp config.log /opt/netcdf4/config.log-netcdf-${NC4C_VERSION} && \
    rm -rf /build

# add netcdf-fortran
# compiling against this requires -lnetcdff (note the extra f)
RUN mkdir -p /build /opt/netcdf4 && cd /build && \
    curl -O ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-fortran-${NC4F_VERSION}.tar.gz && \
    tar xzf netcdf-fortran-${NC4F_VERSION}.tar.gz && \
    cd netcdf-fortran-${NC4F_VERSION} && \
    CPPFLAGS="-I/opt/hdf4/include -I/opt/hdf5/include -I/opt/netcdf4/include" \
    LDFLAGS="-L/opt/hdf4/lib -L/opt/hdf5/lib -L/opt/netcdf4/lib" \
    LD_LIBRARY_PATH="/opt/hdf4/lib:/opt/hdf5/lib:/opt/netcdf4/lib" \
    LIBS="-lnetcdf -ldf -lhdf5_hl -lhdf5 -ljpeg -lm -lz" \
    ./configure --prefix="/opt/netcdf4" --disable-dap --with-pic && make -j4 && make install && \
    cp config.log /opt/netcdf4/config.log-netcdff-${NC4F_VERSION} && \
    rm -rf /build

# throw in some minor shell niceties
RUN echo 'alias ls="ls --color=auto"' >> ~/.bashrc && \
    echo 'alias ll="ls -lGh $@"' >> ~/.bashrc

RUN echo "export HDF4=/opt/hdf4" >> ~/.bashrc && \
    echo "export HDF5=/opt/hdf5" >> ~/.bashrc && \
    echo "export NETCDF=/opt/netcdf4" >> ~/.bashrc && \
    echo "export LD_LIBRARY_PATH=${HDF4}/lib:${HDF5}/lib:${NETCDF}/lib:${LD_LIBRARY_PATH}" >> ~/.bashrc && \
    echo "" >> ~/.bashrc


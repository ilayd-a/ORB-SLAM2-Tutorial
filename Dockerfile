
# Use the official Ubuntu 18.04 as a parent image
FROM ubuntu:18.04

ENV TZ=Europe/Istanbul

RUN apt-get update && \
    apt-get install -y tzdata

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    checkinstall \
    cmake \
    git \
    yasm \
    gfortran \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libtbb2 \
    libtbb-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff5-dev \
    libdc1394-22-dev \
    libv4l-dev \
    libeigen3-dev \
    libboost-all-dev \
    qt5-default \
    libatlas-base-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libgoogle-glog-dev \
    libgflags-dev \
    libhdf5-dev \
    doxygen \
    python3 \
    python3-dev \
    python3-pip \
    libopenblas-dev \
    liblapack-dev \
    liblapacke-dev \
    libblas-dev \
    libgtk2.0-dev \
    libatlas-base-dev \
    pkg-config \
    wget \
    libpcl-dev \
    libjasper-dev \
    libdcmtk-dev 
     
# Upgrade pip and setuptools
RUN pip3 install --upgrade pip setuptools

# Install Python packages
RUN pip3 install matplotlib==3.1.3

# Retry logic for installing certain Python packages
RUN bash -c 'for i in {1..10}; do pip3 install --no-cache-dir cython==0.29.21 numpy==1.19.5 scikit-image==0.15.0 scikit-learn==0.22.2.post1 && break || sleep 2; done'

# Install scipy via apt-get
RUN apt-get install -y python3-scipy

# Git configuration
RUN git config --global http.postBuffer 1048576000 \
    && git config --global http.lowSpeedLimit 0 \
    && git config --global http.lowSpeedTime 999999

# Copy OpenCV and OpenCV Contrib repositories into the container
COPY opencv /root/opencv
COPY opencv_contrib /root/opencv_contrib

# Debugging: List contents of /root
RUN ls -l /root \
    && ls -l /root/opencv \
    && ls -l /root/opencv_contrib

# Verify LAPACK library path
RUN find /usr -name "liblapacke.so" -exec ls -l {} \;

# Get the path to liblapacke.so dynamically and build OpenCV
RUN set -e; \
    LAPACKE_PATH=$(find /usr -name "liblapacke.so"); \
    echo "LAPACKE_PATH: $LAPACKE_PATH"; \
    mkdir -p /root/opencv/build; \
    cd /root/opencv/build; \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D INSTALL_C_EXAMPLES=ON \
          -D INSTALL_PYTHON_EXAMPLES=ON \
          -D WITH_TBB=ON \
          -D WITH_V4L=ON \
          -D WITH_QT=ON \
          -D WITH_OPENGL=ON \
          -D OPENCV_EXTRA_MODULES_PATH=/root/opencv_contrib/modules \
          -D BUILD_EXAMPLES=ON \
          -D OPENCV_GENERATE_PKGCONFIG=YES \
          -D LAPACK_INCLUDE_DIR=/usr/include \
          -D LAPACK_LIBRARIES=$LAPACKE_PATH \
          -D CBLAS_INCLUDE_DIR=/usr/include/x86_64-linux-gnu \
          -D BUILD_opencv_gapi=OFF \
          ..; \
    make -j8; \
    make install; \
    sh -c 'echo "/usr/local/lib" >> /etc/ld.so.conf.d/opencv.conf'; \
    ldconfig

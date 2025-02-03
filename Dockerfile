FROM nvidia/cuda:12.5.1-devel-ubuntu22.04
ENV TZ=US \
    DEBIAN_FRONTEND=noninteractive

ARG CUDA_GENERATION=Auto

RUN apt-get update && apt-get install -y \
    clang \
    cmake \
    git \
    libblas-dev \
    libeigen3-dev \
    libgoogle-glog-dev \
    libgtk2.0-dev \
    liblapack-dev \
    libvtk9-dev \
    libproj-dev \
    libsuitesparse-dev \
    libqt5opengl5-dev \
    pkg-config \
    zip


# Make dynfu build dir
RUN mkdir -p dynfu/build


# Get terra
ADD https://github.com/zdevito/terra/releases/download/release-2016-03-25/terra-Linux-x86_64-332a506.zip .
RUN unzip -qq terra-Linux-x86_64-332a506.zip
RUN mv terra-Linux-x86_64-332a506 terra
RUN ln -s /terra /dynfu/build/terra

# Get Opt
RUN git clone https://github.com/mbrookes1304/Opt.git
WORKDIR Opt/API
RUN git checkout env-variables
RUN make
WORKDIR ../..
RUN ln -s /Opt /dynfu/build/Opt

# Install OpenMesh
ADD https://www.graphics.rwth-aachen.de/media/openmesh_static/Releases/11.0/OpenMesh-11.0.0.tar.gz .
RUN tar xzf OpenMesh-11.0.0.tar.gz
WORKDIR OpenMesh-11.0.0
RUN mkdir build
WORKDIR build
RUN cmake -DCMAKE_BUILD_TYPE=Release .. && make install
WORKDIR ../..
RUN rm -rf OpenMesh*
WORKDIR ../..
RUN rm -rf OpenMesh*

# Install ceres-solver
ADD http://ceres-solver.org/ceres-solver-2.2.0.tar.gz .
RUN tar xzf ceres-solver-2.2.0.tar.gz
RUN mkdir ceres-bin
WORKDIR ceres-bin
RUN cmake ../ceres-solver-2.2.0 \
         -D BUILD_EXAMPLES=OFF \
         -D BUILD_TESTING=OFF \
         -D GFLAGS=OFF \
. && make install
WORKDIR ..
RUN rm -rf ceres-solver

# Install FLANN
RUN apt-get install -y libflann-dev

# Install boost
RUN apt-get update && apt-get install -y libboost-all-dev


# Install pcl
ADD https://github.com/PointCloudLibrary/pcl/archive/refs/tags/pcl-1.14.0.tar.gz .
RUN tar xzf pcl-1.14.0.tar.gz
WORKDIR pcl-pcl-1.14.0
RUN mkdir build
WORKDIR build
RUN cmake -D BUILD_keypoints=OFF \
          -D BUILD_ml=OFF \
          -D BUILD_outofcore=OFF \
          -D BUILD_people=OFF \
          -D BUILD_recognition=OFF \
          -D BUILD_registration=OFF \
          -D BUILD_segmentation=OFF \
          -D BUILD_simulation=OFF \
          -D BUILD_stereo=OFF \
          -D BUILD_tools=OFF \
   ..
RUN make install
WORKDIR ../..
RUN rm -rf pcl*

# Download OpenCV_Contrib
RUN git clone https://github.com/opencv/opencv_contrib.git


# Install OpenCV
ADD https://github.com/opencv/opencv/archive/refs/tags/4.11.0.tar.gz .
RUN tar xzf 4.11.0.tar.gz
RUN rm 4.11.0.tar.gz
WORKDIR opencv-4.11.0
RUN rm -rf platforms/android platforms/ios platforms/maven platforms/osx samples/*
RUN mkdir build
WORKDIR build
RUN cmake -D BUILD_DOCS=OFF \
          -D BUILD_PACKAGE=OFF \
          -D BUILD_PERF_TESTS=OFF \
          -D OPENCV_EXTRA_MODULES_PATH=/../../opencv_contrib/modules .. \
          -D BUILD_TESTS=OFF \
          -D BUILD_WITH_DEBUG_INFO=OFF \
          -D BUILD_opencv_apps=OFF \
          -D BUILD_opencv_calib3d=ON \
          -D BUILD_opencv_core=ON \
          -D BUILD_opencv_features2d=ON \
          -D BUILD_opencv_flann=ON \
          -D BUILD_opencv_highgui=ON \
          -D BUILD_opencv_imgcodecs=ON \
          -D BUILD_opencv_imgproc=ON \
          -D BUILD_opencv_ml=ON \
          -D BUILD_opencv_objdetect=OFF \
          -D BUILD_opencv_photo=OFF \
          -D BUILD_opencv_shape=OFF \
          -D BUILD_opencv_stitching=OFF \
          -D BUILD_opencv_superres=OFF \
          -D BUILD_opencv_ts=OFF \
          -D BUILD_opencv_viz=ON \
          -D BUILD_opencv_video=OFF \
          -D BUILD_opencv_videoio=OFF \
          -D BUILD_opencv_videostab=OFF \
          -D BUILD_opencv_video=OFF \
          -D CMAKE_BUILD_TYPE=RELEASE \
          -D CUDA_GENERATION=${CUDA_GENERATION:-Auto} \
          -D WITH_VTK=ON \
    ..
#    
#
RUN make
RUN make install
WORKDIR ../..
RUN rm -rf opencv-4.11.0
RUN rm -rf opencv_contrib

# Add source files
ADD CMakeLists.txt /dynfu
ADD cmake /dynfu/cmake
ADD src /dynfu/src
ADD include /dynfu/include

# Build dynfu
WORKDIR dynfu/build
RUN cmake -D CUDA_CUDA_LIBRARY="/usr/local/cuda/lib64/stubs/libcuda.so" ..
RUN make
WORKDIR ..

# Run dynamicfusion using /data
CMD ./build/bin/app /data

# Rmeove unnecessary packages
RUN apt-get remove -y \
    clang \
    curl \
    git \
    pkg-config \
    zip

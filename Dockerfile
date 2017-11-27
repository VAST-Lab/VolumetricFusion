FROM nvidia/cuda:8.0-devel
ARG CUDA_GENERATION=Auto

RUN apt-get update && apt-get install -y cmake libvtk5-dev python pkg-config libgtk2.0-dev

# Install OpenCV
ADD https://github.com/opencv/opencv/archive/3.2.0.tar.gz .
RUN tar xzf 3.2.0.tar.gz
RUN rm 3.2.0.tar.gz
WORKDIR opencv-3.2.0
RUN rm -rf platforms/android platforms/ios platforms/maven platforms/osx samples/*
RUN mkdir build
WORKDIR build
RUN cmake -D WITH_VTK=ON -D BUILD_opencv_calib3d=ON -D BUILD_opencv_imgproc=ON -D CMAKE_BUILD_TYPE=RELEASE -D BUILD_PYTHON_SUPPORT=ON -D CUDA_GENERATION=${CUDA_GENERATION:-Auto} -D WITH_OPENGL=ON -D WITH_GTK_2_X=ON ..
RUN make -j`nproc`
RUN make install
WORKDIR ../..
RUN rm -rf opencv-3.2.0

RUN apt-get install -y git zip clang libsuitesparse-dev liblapack-dev libblas-dev libeigen3-dev libgoogle-glog-dev

# Install ceres-solver
RUN git clone https://ceres-solver.googlesource.com/ceres-solver
WORKDIR ceres-solver
RUN cmake . && make install
WORKDIR ..
RUN rm -rf ceres-solver

# Install pcl
RUN apt-get install -y libpcl-dev

# Install lcov
RUN apt-get install -y lcov

# Install libproj
RUN apt-get install -y libproj-dev

# Required for libvtk-proj4 due to bug in vtk6
RUN ln -s /usr/lib/x86_64-linux-gnu/libvtkCommonCore-6.2.so /usr/lib/libvtkproj4.so

# Make dynfu
RUN mkdir -p dynfu/build

ADD CMakeLists.txt /dynfu
ADD cmake /dynfu/cmake
ADD src /dynfu/src
ADD include /dynfu/include

WORKDIR dynfu/build
RUN cmake -D CUDA_CUDA_LIBRARY="/usr/local/cuda/lib64/stubs/libcuda.so" ..
RUN make
WORKDIR ..

# Run dynamicfusion using /data
CMD ./build/bin/app /data

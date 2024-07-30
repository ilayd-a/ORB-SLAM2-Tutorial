# ORB-SLAM2-Tutorial

Make sure Docker is installed and open.

## 1) Create a New Directory

First, create a directory where you'll store the Dockerfile and any other files you need. Open your terminal and run:

```console
mkdir orb-slam2-docker
cd orb-slam2-docker
```

## 2) Create the Dockerfile

You can use the Dockerfile in this repo or create your own. In both cases, just make sure its in the orb-slam2-docker directory we've just created.

## 3) Build the Docker Image

Open your terminal, navigate to the directory containing the Dockerfile, and run:

```console
docker build --no-cache -t orb-slam2 .
```

This command builds the Docker image and tags it as orb-slam2.

## 4) Clone ORB-SLAM2 Repository

Clone the ORB-SLAM2 repository from GitHub:

```console
cd /root
git clone https://github.com/raulmur/ORB_SLAM2.git
cd ORB_SLAM2
```

## 5) Download Vocabulary File

Download Vocabulary File:

```console
cd Vocabulary
wget https://github.com/raulmur/ORB_SLAM2/raw/master/Vocabulary/ORBvoc.txt.tar.gz
tar -xzvf ORBvoc.txt.tar.gz
cd ..
```

## 6) Build OpenCV from Source

It was creating problems when I tried to install it using apt-get so I suggest using this:

```console
cd /root
git clone https://github.com/opencv/opencv.git
git clone https://github.com/opencv/opencv_contrib.git
cd opencv
mkdir build
cd build
cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules ..
make -j8
make install
```

## 7) Install Dependencies for Pangolin

Install the required dependencies for Pangolin. Some may already be in the Dockerfile but I just wanted to make sure:

```console
apt-get update
apt-get install -y libglew-dev cmake libpython2.7-dev libeigen3-dev libpthread-stubs0-dev
apt-get install -y libboost-dev libboost-thread-dev libboost-filesystem-dev libepoxy-dev
```

## 8) Clone Pangolin Repository

```console
cd /root
git clone https://github.com/stevenlovegrove/Pangolin.git
cd Pangolin
mkdir build
cd build
```

## 9) Build and Install Pangolin

```console
cmake -DEigen3_DIR=/usr/include/eigen3 ..
cmake --build .
make install
```

## 10) Set Pangolin and Eigen3 Directory for ORB_SLAM2

Make sure the paths are set for ORB_SLAM2 to find both Pangolin and Eigen3:

```console
export Pangolin_DIR=/root/Pangolin/build
export Eigen3_DIR=/usr/include/eigen3
```

## 11) Modify CMakeLists.txt:

Update the CMakeLists.txt to ensure that it correctly includes all source files.

Here's the modified CMakeLists.txt:

```console
cmake_minimum_required(VERSION 2.8)
project(ORB_SLAM2)

IF(NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Release)
ENDIF()

MESSAGE("Build type: " ${CMAKE_BUILD_TYPE})

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}  -Wall  -O3 -march=native ")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall   -O3 -march=native")

# Check C++11 or C++0x support
include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)
if(COMPILER_SUPPORTS_CXX11)
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
   add_definitions(-DCOMPILEDWITHC11)
   message(STATUS "Using flag -std=c++11.")
elseif(COMPILER_SUPPORTS_CXX0X)
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
   add_definitions(-DCOMPILEDWITHC0X)
   message(STATUS "Using flag -std=c++0x.")
else()
   message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
endif()

LIST(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake_modules)

find_package(PkgConfig REQUIRED)
pkg_search_module(Eigen3 REQUIRED eigen3)

find_package(OpenCV 3.0 QUIET)
if(NOT OpenCV_FOUND)
   find_package(OpenCV 2.4.3 QUIET)
   if(NOT OpenCV_FOUND)
      message(FATAL_ERROR "OpenCV > 2.4.3 not found.")
   endif()
endif()

find_package(Pangolin REQUIRED)
find_package(Threads REQUIRED)

include_directories(
${PROJECT_SOURCE_DIR}
${PROJECT_SOURCE_DIR}/include
${Eigen3_INCLUDE_DIRS}
${Pangolin_INCLUDE_DIRS})

set(SOURCE_FILES
    src/main.cc
    src/Tracking.cc
)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/lib)

add_library(ORB_SLAM2_lib SHARED
src/System.cc
src/Tracking.cc
src/LocalMapping.cc
src/LoopClosing.cc
src/ORBextractor.cc
src/ORBmatcher.cc
src/FrameDrawer.cc
src/Converter.cc
src/MapPoint.cc
src/KeyFrame.cc
src/Map.cc
src/MapDrawer.cc
src/Optimizer.cc
src/PnPsolver.cc
src/Frame.cc
src/KeyFrameDatabase.cc
src/Sim3Solver.cc
src/Initializer.cc
src/Viewer.cc
)

target_link_libraries(ORB_SLAM2_lib
${OpenCV_LIBS}
Eigen3::Eigen
${Pangolin_LIBRARIES}
${PROJECT_SOURCE_DIR}/Thirdparty/DBoW2/lib/libDBoW2.so
${PROJECT_SOURCE_DIR}/Thirdparty/g2o/lib/libg2o.so
)

# Build examples
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/Examples/RGB-D)

add_executable(rgbd_tum Examples/RGB-D/rgbd_tum.cc)
target_link_libraries(rgbd_tum ORB_SLAM2_lib)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/Examples/Stereo)

add_executable(stereo_kitti Examples/Stereo/stereo_kitti.cc)
target_link_libraries(stereo_kitti ORB_SLAM2_lib)

add_executable(stereo_euroc Examples/Stereo/stereo_euroc.cc)
target_link_libraries(stereo_euroc ORB_SLAM2_lib)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/Examples/Monocular)

add_executable(mono_tum Examples/Monocular/mono_tum.cc)
target_link_libraries(mono_tum ORB_SLAM2_lib)

add_executable(mono_kitti Examples/Monocular/mono_kitti.cc)
target_link_libraries(mono_kitti ORB_SLAM2_lib)

add_executable(mono_euroc Examples/Monocular/mono_euroc.cc)
target_link_libraries(mono_euroc ORB_SLAM2_lib)
```

## 12)  Build g2o

```
```

```console
cd /root/ORB_SLAM2/Thirdparty/g2o
mkdir build
cd build
cmake ..
make -j4
```

## 13) Build DBoW2:

Navigate to the DBoW2 directory and build it:

```console
cd /root/ORB_SLAM2/Thirdparty/DBoW2
mkdir build
cd build
cmake ..
make -j4
```

## 14) Edit the source files to include unistd.h:

For each source file with the usleep error, add the following line at the top of the file:

```console
#include <unistd.h>
```

Specifically, you need to edit:

- LocalMapping.cc
- LoopClosing.cc
- System.cc
- Tracking.cc
- Viewer.cc
- Examples/Stereo/stereo_kitti.cc
- Examples/Monocular/mono_euroc.cc
- Examples/RGB-D/rgbd_tum.cc
- Examples/Stereo/stereo_euroc.cc
- Examples/Monocular/mono_kitti.cc
-
  
You can edit these files using nano from your terminal:

```console
nano /root/ORB_SLAM2/src/LocalMapping.cc
```

## 15) Build ORB-SLAM2:

```console
chmod +x build.sh
./build.sh
```

## 16) Run the executable with your video frames:

```console
./Examples/Monocular/mono_kitti path_to_vocabulary_file path_to_settings_file path_to_image_directory
```

For example:
```console
./Examples/Monocular/mono_kitti Vocabulary/ORBvoc.txt Examples/Monocular/KITTI00-02.yaml Examples/Monocular/video_frames
```

## python version >= 3.9
sudo yum -y groupinstall "Development Tools"
sudo yum -y install openssl-devel bzip2-devel libffi-devel
curl -O https://www.python.org/ftp/python/3.9.10/Python-3.9.10.tgz
tar xvf Python-3.9.10.tgz
cd Python-*/
./configure --enable-optimizations
sudo make altinstall

python3.9 -m pip install --upgrade pip

sudo yum install gcc-gfortran python3-devel atlas-devel pkgconfig

## virtualenv
cd /home/$(whoami)
pip install virtualenv
python3.9 -m virtualenv env
source env/bin/activate

## numpy 
pip install cython
curl -L -o numpy-1.24.2.tar.gz https://github.com/numpy/numpy/archive/refs/tags/v1.24.2.tar.gz
tar xvf numpy-1.24.2.tar.gz
cd numpy-1.24.2

### build numpy
NPY_DISABLE_SVML=1 CFLAGS='-g0 -Wl,--strip-all -Os -I/usr/include:/usr/local/include' python setup.py build --fcompiler=gnu95 install

BUILDFOLDER="/home/$(whoami)/aws-lambda-layer"
mkdir -p $BUILDFOLDER/python/lib/python3.9/site-packages/
cp -rP /home/$(whoami)/env/lib/python3.9/site-packages/numpy $BUILDFOLDER/python/lib/python3.9/site-packages
mkdir $BUILDFOLDER/lib
cp -rP /usr/lib64/atlas $BUILDFOLDER/lib
cp -P /usr/lib64/libquadmath.so* $BUILDFOLDER/lib
cp -P /usr/lib64/libgfortran.so* $BUILDFOLDER/lib

## scipy
pip install pythran
pip install pybind11

cd /home/$(whoami)
git clone https://github.com/scipy/scipy.git
cd scipy
git checkout maintenance/1.10.x
git submodule update --init

### build scipy
NPY_DISABLE_SVML=1 CFLAGS='-g0 -Wl,--strip-all -Os -I/usr/include:/usr/local/include' python setup.py install

cp -rP /home/$(whoami)/env/lib/python3.9/site-packages/scipy*/scipy $BUILDFOLDER/python/lib/python3.9/site-packages

## opencv
sudo yum install cmake3

cd /home/$(whoami)/
curl -Lo opencv.zip https://github.com/opencv/opencv/archive/4.x.zip
mkdir opencvBuild
cd opencvBuildC
cmake3 \
-DBUILD_LIST=core,imgcodecs,imgproc,python3 \
-DWITH_OPENCL=OFF \
-DCMAKE_BUILD_TYPE=RELEASE \
-DWITH_V4L=OFF \
-DWITH_IMGCODEC_PFM=OFF \
-DWITH_IMGCODEC_PXM=OFF \
-DWITH_IMGCODEC_SUNRASTER=OFF \
-DWITH_IMG_CODEC_HDR=OFF \
-DWITH_OPENEXR=OFF \
-DWITH_JASPER=OFF \
-DWITH_JPEG=OFF \
-DWITH_WEBP=OFF \
-DWITH_TIFF=OFF \
-DBUILD_TESTS=ON \
-DBUILD_PERF_TESTS=ON \
../

cmake --build . --target install/strip

sudo mv /usr/local/lib/python3.9/site-packages/cv2 $BUILDFOLDER/python/lib/python3.9/site-packages

sudo mv /usr/local/lib64/libopencv* $BUILDFOLDER/lib

cd $BUILDFOLDER
zip --symlinks -r build.zip .
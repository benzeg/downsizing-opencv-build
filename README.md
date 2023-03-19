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
pip install virtualenv
python3.9 -m virtualenv env
source env/bin/activate

## numpy 
pip install cython
curl -L -o numpy-1.24.2.tar.gz https://github.com/numpy/numpy/archive/refs/tags/v1.24.2.tar.gz
tar xvf numpy-1.24.2.tar.gz
cd numpy-1.24.2

BUILDFOLDER="/home/$(whoami)/aws-lambda-layer"
mkdir -p $BUILDFOLDER/python/lib/python3.9/site-packages/

### build numpy
#### use -g0 to strip debug symbols
#### use -Wl,--strip-all to strip all symbols
#### use -O2 to optimize space and time
#### use -I/usr/include:/usr/local/include to include system and local header files
NPY_DISABLE_SVML=1 CFLAGS='-g0 -Wl,--strip-all -O2 -I/usr/include:/usr/local/include' python setup.py build --fcompiler=gnu95 install

mv /home/$(whoami)/env/lib/python3.9/site-packages/numpy*/numpy $BUILDFOLDER/python/lib/python3.9/site-packages/numpy
cd /home/$(whoami)/env/lib/python3.9/site-packages
ln -s $BUILDFOLDER/python/lib/python3.9/site-packages/numpy numpy

#### <pre>(env) [ec2-user@ip-172-31-19-197 site-packages]$ ls
#### <font color="#005FFF">Cython</font>                    <font color="#005FFF">_distutils_hack</font>           <font color="#00FFFF">numpy</font>                                <font color="#005FFF">pip-21.2.4.dist-info</font>  <font color="#005FFF">pybind11-2.10.4.dist-info</font>  <font color="#005FFF">setuptools</font>
#### <font color="#005FFF">Cython-0.29.33.dist-info</font>  distutils-precedence.pth  <font color="#005FFF">numpy-1.24.2-py3.9-linux-x86_64.egg</font>  <font color="#005FFF">pkg_resources</font>         <font color="#005FFF">__pycache__</font>                <font color="#005FFF">setuptools-58.1.0.dist-info</font>
#### cython.py                 easy-install.pth          <font color="#005FFF">pip</font>                                  <font color="#005FFF">pybind11</font>              <font color="#005FFF">pyximport</font>
#### </pre>


### Validate
##### <pre>(env) [ec2-user@ip-172-31-19-197 site-packages]$ /bin/bash -c &quot;python -c &apos;import numpy as np; np.__config__.show();&apos;&quot;
##### blas_armpl_info:
#####   NOT AVAILABLE
##### blas_mkl_info:
#####   NOT AVAILABLE
##### blis_info:
#####   NOT AVAILABLE
##### openblas_info:
#####   NOT AVAILABLE
##### accelerate_info:
#####   NOT AVAILABLE
##### atlas_3_10_blas_threads_info:
#####     language = c
#####     define_macros = [(&apos;HAVE_CBLAS&apos;, None), (&apos;NO_ATLAS_INFO&apos;, -1)]
#####     libraries = [&apos;tatlas&apos;, &apos;tatlas&apos;]
#####     library_dirs = [&apos;/usr/lib64/atlas&apos;]
##### blas_opt_info:
#####     language = c
#####     define_macros = [(&apos;HAVE_CBLAS&apos;, None), (&apos;NO_ATLAS_INFO&apos;, -1)]
#####     libraries = [&apos;tatlas&apos;, &apos;tatlas&apos;]
#####     library_dirs = [&apos;/usr/lib64/atlas&apos;]
##### lapack_armpl_info:
#####   NOT AVAILABLE
##### lapack_mkl_info:
#####   NOT AVAILABLE
##### openblas_lapack_info:
#####   NOT AVAILABLE
##### openblas_clapack_info:
#####   NOT AVAILABLE
##### flame_info:
#####   NOT AVAILABLE
##### atlas_3_10_threads_info:
#####     language = f77
#####     libraries = [&apos;tatlas&apos;, &apos;tatlas&apos;, &apos;tatlas&apos;, &apos;tatlas&apos;]
#####     library_dirs = [&apos;/usr/lib64/atlas&apos;]
#####     define_macros = [(&apos;NO_ATLAS_INFO&apos;, -1)]
##### lapack_opt_info:
#####     language = f77
#####     libraries = [&apos;tatlas&apos;, &apos;tatlas&apos;, &apos;tatlas&apos;, &apos;tatlas&apos;]
#####     library_dirs = [&apos;/usr/lib64/atlas&apos;]
#####     define_macros = [(&apos;NO_ATLAS_INFO&apos;, -1)]
##### Supported SIMD extensions in this NumPy install:
#####     baseline = SSE,SSE2,SSE3
#####     found = SSSE3,SSE41,POPCNT,SSE42,AVX,F16C,FMA3,AVX2
#####     not found = AVX512F,AVX512CD,AVX512_KNL,AVX512_KNM,AVX512_SKX,AVX512_CNL
##### </pre>

#### package atlas, quadmath, gfortran into host 
#### preserve symlinks
mkdir $BUILDFOLDER/lib
cp -rP /usr/lib64/atlas $BUILDFOLDER/lib
cp -P /usr/lib64/libquadmath.so* $BUILDFOLDER/lib
cp -P /usr/lib64/libgfortran.so* $BUILDFOLDER/lib
##### <pre>(env) [ec2-user@ip-172-31-19-197 aws-lambda-layer]$ ls lib
##### <font color="#00FFFF">libgfortran.so.4</font>      <font color="#00FFFF">libquadmath.so.0</font>      <font color="#00FFFF">libsatlas.so</font>    <font color="#00AF00">libsatlas.so.3.10</font>  <font color="#00FFFF">libtatlas.so.3</font>
##### <font color="#00AF00">libgfortran.so.4.0.0</font>  <font color="#00AF00">libquadmath.so.0.0.0</font>  <font color="#00FFFF">libsatlas.so.3</font>  <font color="#00FFFF">libtatlas.so</font>       <font color="#00AF00">libtatlas.so.3.10</font>
##### </pre>

#### package size
### <pre>(env) [ec2-user@ip-172-31-19-197 ~]$ du -sh aws-lambda-layer
### 54M	aws-lambda-layer
### </pre>

##### <pre>[ec2-user@ip-172-31-19-197 site-packages]$ du -sh numpy/*
##### 420K	numpy/array_api
##### 88K	numpy/compat
##### 8.0K	numpy/__config__.py
##### 8.0K	numpy/conftest.py
##### 15M	numpy/core
##### 20K	numpy/ctypeslib.py
##### 8.0K	numpy/ctypeslib.pyi
##### 4.0K	numpy/_distributor_init.py
##### 1.9M	numpy/distutils
##### 44K	numpy/doc
##### 4.0K	numpy/dual.py
##### 1.6M	numpy/f2py
##### 284K	numpy/fft
##### 4.0K	numpy/_globals.py
##### 36K	numpy/__init__.cython-30.pxd
##### 36K	numpy/__init__.pxd
##### 16K	numpy/__init__.py
##### 148K	numpy/__init__.pyi
##### 3.3M	numpy/lib
##### 4.0K	numpy/LICENSE.txt
##### 568K	numpy/linalg
##### 1.4M	numpy/ma
##### 12K	numpy/matlib.py
##### 208K	numpy/matrixlib
##### 1.2M	numpy/polynomial
##### 92K	numpy/__pycache__
##### 28K	numpy/_pyinstaller
##### 8.0K	numpy/_pytesttester.py
##### 4.0K	numpy/_pytesttester.pyi
##### 0	numpy/py.typed
##### 3.7M	numpy/random
##### 4.0K	numpy/setup.py
##### 484K	numpy/testing
##### 124K	numpy/tests
##### 1.1M	numpy/typing
##### 160K	numpy/_typing
##### 4.0K	numpy/_version.py
##### 4.0K	numpy/version.py
##### </pre>

###### common issues

#### <pre>(env) [ec2-user@ip-172-31-19-197 ~]$ /bin/bash -c &quot;python -c &apos;import numpy as np; print(np.__version__)&apos;&quot;
#### Traceback (most recent call last):
####   File &quot;/home/ec2-user/env/lib/python3.9/site-packages/numpy-1.24.2+23.gf14cd4457-py3.9-linux-x86_64.egg/numpy/core/__init__.py&quot;, line 23, in &lt;module&gt;
####     from . import multiarray
####   File &quot;/home/ec2-user/env/lib/python3.9/site-packages/numpy-1.24.2+23.gf14cd4457-py3.9-linux-x86_64.egg/numpy/core/multiarray.py&quot;, line 10, in &lt;module&gt;
####     from . import overrides
####   File &quot;/home/ec2-user/env/lib/python3.9/site-packages/numpy-1.24.2+23.gf14cd4457-py3.9-linux-x86_64.egg/numpy/core/overrides.py&quot;, line 6, in &lt;module&gt;
####     from numpy.core._multiarray_umath import (
#### ImportError: libsatlas.so.3: cannot open shared object file: No such file or directory
#### </pre>


#### <pre>(env) [ec2-user@ip-172-31-19-197 ~]$ /bin/bash -c &quot;python -c &apos;import numpy as np; np.__version__;&apos;&quot;
#### Traceback (most recent call last):
####   File &quot;/home/ec2-user/env/lib/python3.9/site-packages/numpy-1.24.2+23.gf14cd4457-py3.9-linux-x86_64.egg/numpy/core/__init__.py&quot;, line 23, in &lt;module&gt;
####     from . import multiarray
####   File &quot;/home/ec2-user/env/lib/python3.9/site-packages/numpy-1.24.2+23.gf14cd4457-py3.9-linux-x86_64.egg/numpy/core/multiarray.py&quot;, line 10, in &lt;module&gt;
####     from . import overrides
####   File &quot;/home/ec2-user/env/lib/python3.9/site-packages/numpy-1.24.2+23.gf14cd4457-py3.9-linux-x86_64.egg/numpy/core/overrides.py&quot;, line 6, in &lt;module&gt;
####     from numpy.core._multiarray_umath import (
#### ImportError: /home/ec2-user/env/lib/python3.9/site-packages/numpy-1.24.2+23.gf14cd4457-py3.9-linux-x86_64.egg/numpy/core/_multiarray_umath.cpython-39-x86_64-linux-gnu.so: undefined symbol: cblas_sgemm
#### 
#### </pre>

## scipy
pip install pythran
pip install pybind11

cd /home/$(whoami)/env/lib/python3.9/site-packages
ln -s $BUILDFOLDER/python/lib/python3.9/site-packages/numpy numpy
cd /home/$(whoami)/
git clone https://github.com/scipy/scipy.git
cd scipy
git checkout maintenance/1.10.x
git submodule update --init

### build scipy
NPY_DISABLE_SVML=1 CFLAGS='-g0 -Wl,--strip-all -O2 -I/usr/include:/usr/local/include' python setup.py install

#### validate
##### (env) [ec2-user@ip-172-31-19-197 site-packages]$ /bin/bash -c "python -c 'import scipy; scipy.__config__.show();'"
##### lapack_armpl_info:
#####   NOT AVAILABLE
##### lapack_mkl_info:
#####   NOT AVAILABLE
##### openblas_lapack_info:
#####   NOT AVAILABLE
##### openblas_clapack_info:
#####   NOT AVAILABLE
##### flame_info:
#####   NOT AVAILABLE
##### accelerate_info:
#####   NOT AVAILABLE
##### atlas_3_10_threads_info:
#####     language = f77
#####     libraries = ['tatlas', 'tatlas', 'tatlas', 'tatlas']
#####     library_dirs = ['/usr/lib64/atlas']
#####     define_macros = [('NO_ATLAS_INFO', -1)]
##### lapack_opt_info:
#####     language = f77
#####     libraries = ['tatlas', 'tatlas', 'tatlas', 'tatlas']
#####     library_dirs = ['/usr/lib64/atlas']
#####     define_macros = [('NO_ATLAS_INFO', -1)]
##### blas_armpl_info:
#####   NOT AVAILABLE
##### blas_mkl_info:
#####   NOT AVAILABLE
##### blis_info:
#####   NOT AVAILABLE
##### openblas_info:
#####   NOT AVAILABLE
##### atlas_3_10_blas_threads_info:
#####     language = c
#####     define_macros = [('HAVE_CBLAS', None), ('NO_ATLAS_INFO', -1)]
#####     libraries = ['tatlas', 'tatlas']
#####     library_dirs = ['/usr/lib64/atlas']
##### blas_opt_info:
#####     language = c
#####     define_macros = [('HAVE_CBLAS', None), ('NO_ATLAS_INFO', -1)]
#####     libraries = ['tatlas', 'tatlas']
#####     library_dirs = ['/usr/lib64/atlas']
##### Supported SIMD extensions in this NumPy install:
#####     baseline = SSE,SSE2,SSE3
#####     found = SSSE3,SSE41,POPCNT,SSE42,AVX,F16C,FMA3,AVX2
#####     not found = AVX512F,AVX512CD,AVX512_KNL,AVX512_KNM,AVX512_SKX,AVX512_CNL
##### 

mv /home/$(whoami)/env/lib/python3.9/site-packages/scipy*/scipy $BUILDFOLDER/python/lib/python3.9/site-packages/scipy

##### <pre>[ec2-user@ip-172-31-19-197 site-packages]$ du -sh scipy/*
##### 88K	scipy/_build_utils
##### 1.2M	scipy/cluster
##### 8.0K	scipy/__config__.py
##### 4.0K	scipy/conftest.py
##### 412K	scipy/constants
##### 72K	scipy/datasets
##### 4.0K	scipy/_distributor_init.py
##### 4.0K	scipy/doc_requirements.txt
##### 1.4M	scipy/fft
##### 1.1M	scipy/fftpack
##### 16K	scipy/HACKING.rst.txt
##### 8.0K	scipy/__init__.py
##### 8.0K	scipy/INSTALL.rst.txt
##### 2.6M	scipy/integrate
##### 4.2M	scipy/interpolate
##### 2.8M	scipy/io
##### 872K	scipy/_lib
##### 12K	scipy/LICENSES_bundled.txt
##### 4.0K	scipy/LICENSE.txt
##### 8.8M	scipy/linalg
##### 4.0K	scipy/linalg.pxd
##### 4.0K	scipy/meson_options.txt
##### 2.3M	scipy/misc
##### 4.0K	scipy/mypy_requirements.txt
##### 1.6M	scipy/ndimage
##### 760K	scipy/odr
##### 9.7M	scipy/optimize
##### 4.0K	scipy/optimize.pxd
##### 32K	scipy/__pycache__
##### 4.0K	scipy/setup.py
##### 3.8M	scipy/signal
##### 12M	scipy/sparse
##### 5.8M	scipy/spatial
##### 13M	scipy/special
##### 4.0K	scipy/special.pxd
##### 15M	scipy/stats
##### 4.0K	scipy/version.py
##### </pre>


#### package size
##### <pre>(env) [ec2-user@ip-172-31-19-197 ~]$ du -sh aws-lambda-layer
##### 140M	aws-lambda-layer
##### </pre>

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

#### package size
##### <pre>[ec2-user@ip-172-31-19-197 aws-lambda-layer]$ du -sh lib/*
##### 0	lib/libgfortran.so.4
##### 1.9M	lib/libgfortran.so.4.0.0
##### 0	lib/libopencv_core.so
##### 0	lib/libopencv_core.so.407
##### 15M	lib/libopencv_core.so.4.7.0
##### 0	lib/libopencv_imgcodecs.so
##### 0	lib/libopencv_imgcodecs.so.407
##### 580K	lib/libopencv_imgcodecs.so.4.7.0
##### 0	lib/libopencv_imgproc.so
##### 0	lib/libopencv_imgproc.so.407
##### 25M	lib/libopencv_imgproc.so.4.7.0
##### 0	lib/libquadmath.so.0
##### 248K	lib/libquadmath.so.0.0.0
##### 0	lib/libsatlas.so
##### 0	lib/libsatlas.so.3
##### 11M	lib/libsatlas.so.3.10
##### 0	lib/libtatlas.so
##### 0	lib/libtatlas.so.3
##### 11M	lib/libtatlas.so.3.10
##### </pre>

##### <pre>[ec2-user@ip-172-31-19-197 ~]$ du -sh aws-lambda-layer
##### 181M	aws-lambda-layer
##### </pre>

##### common issues
###### <pre>(env) [ec2-user@ip-172-31-19-197 opencvBuild]$ cmake ../opencv-4.x
###### /home/ec2-user/opencv-4.x
###### CMake Error at CMakeLists.txt:12 (message):
######   
###### 
######   FATAL: In-source builds are not allowed.
###### 
######          You should create a separate directory for build files.
###### 
###### 
###### 
###### -- Configuring incomplete, errors occurred!
###### </pre>

###### delete CMakeCache.txt


cd $BUILDFOLDER
zip --symlinks -r build.zip .
## sources
#### https://numpy.org/doc/stable/user/building.html
#### http://bickson.blogspot.com/2011/02/installing-blaslapackitpp-on-amaon-ec2.html
#### https://docs.scipy.org/doc/scipy/dev/contributor/building.html
#### https://towardsdatascience.com/how-to-shrink-numpy-scipy-pandas-and-matplotlib-for-your-data-product-4ec8d7e86ee4
#### https://github.com/aeddi/aws-lambda-python-opencv/blob/master/build.sh - update rpath
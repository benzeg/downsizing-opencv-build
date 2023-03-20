# Downsizing OpenCV Build
Building OpenCV from source can produce a significantly smaller package size when nonessential modules are omitted and all symbols are stripped from the object files. This method produces a custom build of NumPy,SciPy,OpenCV that takes up 175MB.

## Python verion >= 3.9
```bash
sudo yum -y groupinstall "Development Tools"
sudo yum -y install openssl-devel bzip2-devel libffi-devel
curl -O https://www.python.org/ftp/python/3.9.10/Python-3.9.10.tgz
tar xvf Python-3.9.10.tgz
cd Python-*/
./configure --enable-optimizations
sudo make altinstall

python3.9 -m pip install --upgrade pip
```

## Shared Libraries

```bash
sudo yum install gcc-gfortran python3-devel atlas-devel pkgconfig
```

`python3-devel` This package contains the header files and configuration needed to compile
Python extension modules (typically written in C or C++), to embed Python
into other programs, and to make binary distributions for Python libraries.
It also contains the necessary macros to build RPM packages with Python modules
and 2to3 tool, an automatic source converter from Python 2.X.  

`atlas-devel` This package contains the libraries and headers for development
with ATLAS (Automatically Tuned Linear Algebra Software). An alternative to BLAS/LAPACK

`gcc-fortran` This package contains Fortran shared library which is needed to run
Fortran dynamically linked programs. e.g. Atlas 

## virtualenv
```bash
cd /home/$(whoami)
pip install virtualenv
python3.9 -m virtualenv env
source env/bin/activate
```
Make sure the workspace is clean before we start to build

## NumPy
```
pip install cython
curl -L -o numpy-1.24.2.tar.gz https://github.com/numpy/numpy/archive/refs/tags/v1.24.2.tar.gz
tar xvf numpy-1.24.2.tar.gz
cd numpy-1.24.2
```

`cython` is an optimising static compiler for both the Python programming language and the extended Cython programming language (based on Pyrex). 

### Build
```
NPY_DISABLE_SVML=1 CFLAGS='-g0 -Wl,--strip-all -Os -I/usr/include:/usr/local/include' python setup.py build --fcompiler=gnu95 install
```

Tell gcc to optimize the object code with:
- `-g0` omit code used for debugging
- `-wl,--strip-all` remove all symbols
- `-Os` optimize for code size w/o causing side effects on execution time or memory usage

### Validate
<pre>(env) [ec2-user@ip-172-31-19-197 site-packages]$ /bin/bash -c &quot;python -c &apos;import numpy as np; np.__config__.show();&apos;&quot;
blas_armpl_info:
  NOT AVAILABLE
blas_mkl_info:
  NOT AVAILABLE
blis_info:
  NOT AVAILABLE
openblas_info:
  NOT AVAILABLE
accelerate_info:
  NOT AVAILABLE
atlas_3_10_blas_threads_info:
    language = c
    define_macros = [(&apos;HAVE_CBLAS&apos;, None), (&apos;NO_ATLAS_INFO&apos;, -1)]
    libraries = [&apos;tatlas&apos;, &apos;tatlas&apos;]
    library_dirs = [&apos;/usr/lib64/atlas&apos;]
blas_opt_info:
    language = c
    define_macros = [(&apos;HAVE_CBLAS&apos;, None), (&apos;NO_ATLAS_INFO&apos;, -1)]
    libraries = [&apos;tatlas&apos;, &apos;tatlas&apos;]
    library_dirs = [&apos;/usr/lib64/atlas&apos;]
lapack_armpl_info:
  NOT AVAILABLE
lapack_mkl_info:
  NOT AVAILABLE
openblas_lapack_info:
  NOT AVAILABLE
openblas_clapack_info:
  NOT AVAILABLE
flame_info:
  NOT AVAILABLE
atlas_3_10_threads_info:
    language = f77
    libraries = [&apos;tatlas&apos;, &apos;tatlas&apos;, &apos;tatlas&apos;, &apos;tatlas&apos;]
    library_dirs = [&apos;/usr/lib64/atlas&apos;]
    define_macros = [(&apos;NO_ATLAS_INFO&apos;, -1)]
lapack_opt_info:
    language = f77
    libraries = [&apos;tatlas&apos;, &apos;tatlas&apos;, &apos;tatlas&apos;, &apos;tatlas&apos;]
    library_dirs = [&apos;/usr/lib64/atlas&apos;]
    define_macros = [(&apos;NO_ATLAS_INFO&apos;, -1)]
Supported SIMD extensions in this NumPy install:
    baseline = SSE,SSE2,SSE3
    found = SSSE3,SSE41,POPCNT,SSE42,AVX,F16C,FMA3,AVX2
    not found = AVX512F,AVX512CD,AVX512_KNL,AVX512_KNM,AVX512_SKX,AVX512_CNL
</pre>


AWS Lambda Layer expects its package directories to be structured like so:
<pre>
├── bin
├── lib                       | maps to /usr/lib64
├── python
│   ├── lib 
│   └── python3.9 
│       ├── site-packages 
|           ├── ...
</pre>

```sh
BUILDFOLDER="/home/$(whoami)/aws-lambda-layer"
mkdir -p $BUILDFOLDER/python/lib/python3.9/site-packages/
cp -rP /home/$(whoami)/env/lib/python3.9/site-packages/numpy $BUILDFOLDER/python/lib/python3.9/site-packages
```
Create the package directories then copy the NumPy package into it.<br/>

```sh
mkdir $BUILDFOLDER/lib
cp -rP /usr/lib64/atlas $BUILDFOLDER/lib
cp -P /usr/lib64/libquadmath.so* $BUILDFOLDER/lib
cp -P /usr/lib64/libgfortran.so* $BUILDFOLDER/lib
```
<pre>(env) [ec2-user@ip-172-31-19-197 aws-lambda-layer]$ ls lib
<font color="#00FFFF">libgfortran.so.4</font>      <font color="#00FFFF">libquadmath.so.0</font>      <font color="#00FFFF">libsatlas.so</font>    <font color="#00AF00">libsatlas.so.3.10</font>  <font color="#00FFFF">libtatlas.so.3</font>
<font color="#00AF00">libgfortran.so.4.0.0</font>  <font color="#00AF00">libquadmath.so.0.0.0</font>  <font color="#00FFFF">libsatlas.so.3</font>  <font color="#00FFFF">libtatlas.so</font>       <font color="#00AF00">libtatlas.so.3.10</font>
</pre>

Copy the the shared libraries and its symlinks into it.

### Package size

<pre>
(env) [ec2-user@ip-172-31-19-197 ~]$ du -sh aws-lambda-layer
58M	aws-lambda-layer
</pre>

<pre>(env) [ec2-user@ip-172-31-15-193 ~]$ du -sh aws-lambda-layer/python/lib/python3.9/site-packages/numpy/*
4.0K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/LICENSE.txt
8.0K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/__config__.py
36K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/__init__.cython-30.pxd
36K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/__init__.pxd
16K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/__init__.py
148K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/__init__.pyi
104K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/__pycache__
4.0K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/_distributor_init.py
4.0K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/_globals.py
28K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/_pyinstaller
8.0K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/_pytesttester.py
4.0K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/_pytesttester.pyi
188K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/_typing
4.0K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/_version.py
472K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/array_api
88K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/compat
8.0K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/conftest.py
14M	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/core
20K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/ctypeslib.py
8.0K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/ctypeslib.pyi
2.0M	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/distutils
44K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/doc
4.0K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/dual.py
1.6M	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/f2py
288K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/fft
3.3M	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/lib
544K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/linalg
1.5M	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/ma
12K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/matlib.py
240K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/matrixlib
1.3M	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/polynomial
0	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/py.typed
3.2M	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/random
4.0K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/setup.py
500K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/testing
152K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/tests
992K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/typing
4.0K	aws-lambda-layer/python/lib/python3.9/site-packages/numpy/version.py
</pre>
### Common issues

<pre>
ImportError: libsatlas.so.3: cannot open shared object file: No such file or directory
</pre>
Be sure that the shared libraries are in the host package

<pre>
ImportError: /home/ec2-user/env/lib/python3.9/site-packages/numpy-1.24.2+23.gf14cd4457-py3.9-linux-x86_64.egg/numpy/core/_multiarray_umath.cpython-39-x86_64-linux-gnu.so: undefined symbol: cblas_sgemm
</pre>
Be sure that that the cblas header exists in /usr/include:/usr/local/include.

## SciPy

### Dependencies
```sh
pip install pythran
pip install pybind11
cd /home/$(whoami)/
git clone https://github.com/scipy/scipy.git
cd scipy
git checkout maintenance/1.10.x
git submodule update --init
```

### Build
```sh
NPY_DISABLE_SVML=1 CFLAGS='-g0 -Wl,--strip-all -Os -I/usr/include:/usr/local/include' python setup.py install
```

### Validate
```sh
(env) [ec2-user@ip-172-31-19-197 site-packages]$ /bin/bash -c "python -c 'import scipy; scipy.__config__.show();'"
lapack_armpl_info:
  NOT AVAILABLE
lapack_mkl_info:
  NOT AVAILABLE
openblas_lapack_info:
  NOT AVAILABLE
openblas_clapack_info:
  NOT AVAILABLE
flame_info:
  NOT AVAILABLE
accelerate_info:
  NOT AVAILABLE
atlas_3_10_threads_info:
    language = f77
    libraries = ['tatlas', 'tatlas', 'tatlas', 'tatlas']
    library_dirs = ['/usr/lib64/atlas']
    define_macros = [('NO_ATLAS_INFO', -1)]
lapack_opt_info:
    language = f77
    libraries = ['tatlas', 'tatlas', 'tatlas', 'tatlas']
    library_dirs = ['/usr/lib64/atlas']
    define_macros = [('NO_ATLAS_INFO', -1)]
blas_armpl_info:
  NOT AVAILABLE
blas_mkl_info:
  NOT AVAILABLE
blis_info:
  NOT AVAILABLE
openblas_info:
  NOT AVAILABLE
atlas_3_10_blas_threads_info:
    language = c
    define_macros = [('HAVE_CBLAS', None), ('NO_ATLAS_INFO', -1)]
    libraries = ['tatlas', 'tatlas']
    library_dirs = ['/usr/lib64/atlas']
blas_opt_info:
    language = c
    define_macros = [('HAVE_CBLAS', None), ('NO_ATLAS_INFO', -1)]
    libraries = ['tatlas', 'tatlas']
    library_dirs = ['/usr/lib64/atlas']
Supported SIMD extensions in this NumPy install:
    baseline = SSE,SSE2,SSE3
    found = SSSE3,SSE41,POPCNT,SSE42,AVX,F16C,FMA3,AVX2
    not found = AVX512F,AVX512CD,AVX512_KNL,AVX512_KNM,AVX512_SKX,AVX512_CNL
```

```
cp -rP /home/$(whoami)/env/lib/python3.9/site-packages/scipy $BUILDFOLDER/python/lib/python3.9/site-packages/
```
Copy SciPy into host package

### Package size
<pre>(env) [ec2-user@ip-172-31-19-197 ~]$ du -sh aws-lambda-layer
131M	aws-lambda-layer
</pre>
<pre>[ec2-user@ip-172-31-15-193 ~]$ du -sh ~/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/*
16K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/HACKING.rst.txt
8.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/INSTALL.rst.txt
4.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/LICENSE.txt
12K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/LICENSES_bundled.txt
8.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/__config__.py
8.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/__init__.py
48K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/__pycache__
96K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/_build_utils
4.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/_distributor_init.py
776K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/_lib
908K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/cluster
4.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/conftest.py
400K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/constants
80K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/datasets
4.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/doc_requirements.txt
1.3M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/fft
1004K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/fftpack
2.3M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/integrate
3.4M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/interpolate
2.6M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/io
7.6M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/linalg
4.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/linalg.pxd
4.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/meson_options.txt
2.3M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/misc
4.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/mypy_requirements.txt
1.3M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/ndimage
728K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/odr
7.7M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/optimize
4.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/optimize.pxd
4.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/setup.py
3.1M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/signal
9.5M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/sparse
4.8M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/spatial
11M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/special
4.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/special.pxd
13M	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/stats
4.0K	/home/ec2-user/aws-lambda-layer/python/lib/python3.9/site-packages/scipy/version.py</pre>
## OpenCV
### Dependencies
```sh
sudo yum install cmake3
cd /home/$(whoami)/
curl -Lo opencv.zip https://github.com/opencv/opencv/archive/4.x.zip
unzip opencv.zip
```

### Build
```sh
cd opencv-4.x
mkdir build
cmake \
-DCMAKE_C_FLAGS="-g0 -Wl,--strip-all -Os -I/usr/include:/usr/local/include" \
-DCMAKE_CXX_FLAGS="-g0 -Wl,--strip-all -Os -I/usr/include:/usr/local/include" \
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

sudo cmake --build . --target install
```
I just need `core,imgcodecs,imgproc,python3` and `png` support for my usecase.

### Validate
<pre>(env) [ec2-user@ip-172-31-19-197 site-packages]$ /bin/bash -c &quot;python -c &apos;import cv2; print(cv2.__version__);&apos;&quot;
4.7.0-dev
</pre>

```sh
cp -rP /usr/local/lib/python3.9/site-packages/cv2 $BUILDFOLDER/python/lib/python3.9/site-packages
cp -P /usr/local/lib64/libopencv* $BUILDFOLDER/lib
```

### Package size
<pre>(env) [ec2-user@ip-172-31-15-193 ~]$ du -sh aws-lambda-layer
175M	aws-lambda-layer
</pre>

<pre>
(env) [ec2-user@ip-172-31-15-193 ~]$ du -sh aws-lambda-layer/lib/*
0	aws-lambda-layer/lib/libgfortran.so.5
2.9M	aws-lambda-layer/lib/libgfortran.so.5.0.0
0	aws-lambda-layer/lib/libopencv_core.so
16M	aws-lambda-layer/lib/libopencv_core.so.4.7.0
0	aws-lambda-layer/lib/libopencv_core.so.407
0	aws-lambda-layer/lib/libopencv_imgcodecs.so
712K	aws-lambda-layer/lib/libopencv_imgcodecs.so.4.7.0
0	aws-lambda-layer/lib/libopencv_imgcodecs.so.407
0	aws-lambda-layer/lib/libopencv_imgproc.so
27M	aws-lambda-layer/lib/libopencv_imgproc.so.4.7.0
0	aws-lambda-layer/lib/libopencv_imgproc.so.407
0	aws-lambda-layer/lib/libquadmath.so.0
292K	aws-lambda-layer/lib/libquadmath.so.0.0.0
0	aws-lambda-layer/lib/libsatlas.so
0	aws-lambda-layer/lib/libsatlas.so.3
13M	aws-lambda-layer/lib/libsatlas.so.3.10
0	aws-lambda-layer/lib/libtatlas.so
0	aws-lambda-layer/lib/libtatlas.so.3
13M	aws-lambda-layer/lib/libtatlas.so.3.10
</pre>

## Reference 
- https://numpy.org/doc/stable/user/building.html - official docs.
- https://docs.scipy.org/doc/scipy/dev/contributor/building.html - official docs.
- https://towardsdatascience.com/how-to-shrink-numpy-scipy-pandas-and-matplotlib-for-your-data-product-4ec8d7e86ee4 - shrank NumPy to 16M and SciPy to 52M on an older release.
- https://www.rapidtables.com/code/linux/gcc/gcc-o.html#optimization - table on gcc -O flags effects on execution time, memory use, and compile time.
- https://amazonlinux.pkgs.org/2/amazonlinux-core-x86_64/python3-devel-3.7.10-1.amzn2.0.1.x86_64.rpm.html - package description.
- https://amazonlinux.pkgs.org/2/amazonlinux-core-x86_64/libgfortran-7.3.1-14.amzn2.i686.rpm.html - package description.
- https://amazonlinux.pkgs.org/2/amazonlinux-core-x86_64/atlas-devel-3.10.1-12.amzn2.0.2.x86_64.rpm.html - package description.
- https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html#configuration-layers-path - package description.
- https://cython.org/ - package description.

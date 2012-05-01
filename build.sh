#!/bin/bash
GLOBAL_OUTDIR="`pwd`/dependencies"
mkdir -p $GLOBAL_OUTDIR/include $GLOBAL_OUTDIR/lib
OUTDIR="./outdir"

IOS_BASE_SDK="5.1"
IOS_DEPLOY_TGT="5.0"

setenv_all()
{
        # Add internal libs
        export CFLAGS="$CFLAGS -I$GLOBAL_OUTDIR/include -L$GLOBAL_OUTDIR/lib"

#        export CPP="/usr/bin/clang++"
        export CXX="/usr/bin/clang"
#        export CXXCPP="/usr/bin/clang++"
        export CC="/usr/bin/clang"
        export LD=/usr/bin/ld
        export AR=/usr/bin/ar
        export AS=/usr/bin/as
        export NM=/usr/bin/nm
        export RANLIB=/usr/bin/ranlib
        export LDFLAGS="-L$SDKROOT/usr/lib/ -L$DEVROOT/usr/llvm-gcc-4.2/lib"

        export CPPFLAGS=$CFLAGS
        export CXXFLAGS=$CFLAGS
}

setenv_arm6()
{
        unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS

        export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
        export SDKROOT=$DEVROOT/SDKs/iPhoneOS$IOS_BASE_SDK.sdk

        export CFLAGS="-arch armv6 -pipe -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"

        setenv_all
}

setenv_arm7()
{
        unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS

        export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
        export SDKROOT=$DEVROOT/SDKs/iPhoneOS$IOS_BASE_SDK.sdk

        export CFLAGS="-arch armv7 -pipe -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"

        setenv_all
}

setenv_i386()
{
        unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS

        export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer
        export SDKROOT=$DEVROOT/SDKs/iPhoneSimulator$IOS_BASE_SDK.sdk

        export CFLAGS="-arch i386 -pipe -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT"

        setenv_all
}

create_outdir_lipo()
{
        for lib_i386 in `find $OUTDIR/i386 -name "lib*\.a"`; do
                lib_arm6=`echo $lib_i386 | sed "s/i386/arm6/g"`
                lib_arm7=`echo $lib_i386 | sed "s/i386/arm7/g"`
                lib=`echo $lib_i386 | sed "s/i386\///g"`
                lipo -arch armv6 $lib_arm6 -arch armv7 $lib_arm7 -arch i386 $lib_i386 -create -output $lib
        done
}

merge_libfiles()
{
        DIR=$1
        LIBNAME=$2

        cd $DIR
        for i in `find . -name "lib*.a"`; do
                $AR -x $i
        done
        $AR -r $LIBNAME *.o
        rm -rf *.o __*
        cd -
}

rm -rf $OUTDIR
mkdir -p $OUTDIR/arm6 $OUTDIR/arm7 $OUTDIR/i386

make clean 2> /dev/null
make distclean 2> /dev/null
setenv_arm6
# --with-jpeg-lib-dir=$SDKROOT/usr/lib --with-jpeg-include-dir=$SDKROOT/usr/include # no libjpeg by default
./configure --host=arm-apple-darwin6 --enable-shared=no --without-lzma --without-jpeg12 --without-jpeg --with-zlib-lib-dir=$SDKROOT/usr/lib --with-zlib-include-dir=$SDKROOT/usr/include
make -j4
cp -rvf libtiff/.libs/lib*.a $OUTDIR/arm6

make clean 2> /dev/null
make distclean 2> /dev/null
setenv_arm7
./configure --host=arm-apple-darwin7 --enable-shared=no --without-lzma --without-jpeg12 --without-jpeg --with-zlib-lib-dir=$SDKROOT/usr/lib --with-zlib-include-dir=$SDKROOT/usr/include
make -j4
cp -rvf libtiff/.libs/lib*.a $OUTDIR/arm7

make clean 2> /dev/null
make distclean 2> /dev/null
setenv_i386
./configure --enable-shared=no --without-lzma --without-jpeg12 --without-jpeg --with-zlib-lib-dir=$SDKROOT/usr/lib --with-zlib-include-dir=$SDKROOT/usr/include
make -j4
cp -rvf libtiff/.libs/lib*.a $OUTDIR/i386

create_outdir_lipo
mkdir -p $GLOBAL_OUTDIR/include/libtiff && cp -rvf libtiff/*.h $GLOBAL_OUTDIR/include/libtiff
mkdir -p $GLOBAL_OUTDIR/lib && cp -rvf $OUTDIR/lib*.a $GLOBAL_OUTDIR/lib
cd -
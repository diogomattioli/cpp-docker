FROM ubuntu:24.04

ENV TZ=Europe/CET

RUN <<EOF
    apt-get update -y
    apt-get install -y --no-install-recommends tzdata
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo "$TZ" > /etc/timezone
    dpkg-reconfigure --frontend noninteractive tzdata
    
    apt-get install -y --no-install-recommends ca-certificates apt-transport-https wget python3-pip
    apt-get install -y --no-install-recommends git vim-tiny cmake make gcc-14 g++-14
    apt-get install -y --no-install-recommends clang-18 clang-format-18 llvm-18 libclang-rt-18-dev
    apt-get install -y --no-install-recommends libgtest-dev libgmock-dev libbenchmark-dev
    apt-get install -y --no-install-recommends gdb valgrind cppcheck
    apt-get clean

    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100

    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100
    update-alternatives --install /usr/bin/clang-++ clang-++ /usr/bin/clang++-18 100
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-18 100

    pip3 install conan --break-system-packages
EOF

RUN useradd -m -s /bin/bash user
USER user
WORKDIR /home/user

COPY conanfile.txt /home/user/

RUN <<EOF
    conan profile detect
    sed -i 's/compiler.cppstd=.*/compiler.cppstd=20/' ~/.conan2/profiles/default
    cp ~/.conan2/profiles/default ~/.conan2/profiles/release
    cp ~/.conan2/profiles/default ~/.conan2/profiles/debug
    sed -i 's/build_type=.*/build_type=Debug/' ~/.conan2/profiles/debug
    conan install ./conanfile.txt --build=missing --profile debug
    conan install ./conanfile.txt --build=missing --profile release
    rm -rf conanfile.txt build
EOF

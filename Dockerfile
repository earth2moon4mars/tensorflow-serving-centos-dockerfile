FROM centos:centos7.9.2009

ARG TF_SERVING_VERSION_GIT_BRANCH=r2.8
ARG TF_SERVING_VERSION_GIT_COMMIT=HEAD

LABEL maintainer=gvasudevan@google.com
LABEL tensorflow_serving_github_branchtag=${TF_SERVING_VERSION_GIT_BRANCH}
LABEL tensorflow_serving_github_commit=${TF_SERVING_VERSION_GIT_COMMIT}

ARG TF_SERVING_BUILD_OPTIONS="--config=release"
ARG TF_SERVING_BAZEL_OPTIONS=""

RUN yum -y update && yum -y install \
        automake \
        build-essential \
        ca-certificates \
        curl \
        git \
        libcurl3-dev \
        libfreetype6-dev \
        libpng-dev \
        libtool \
        libzmq3-dev \
        mlocate \
        pkg-config \
        python-dev \
        software-properties-common \
        java-1.8.0-openjdk-devel \
        swig \
        unzip \
        wget \
        zip \
        zlib1g-dev \
        python3-distutils \
        centos-release-scl \
        yum-utils \
        patch \
        which \
        && \
    yum clean all
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms
RUN yum -y update && yum install -y \
    devtoolset-8-gcc*

# Install python 3.7.
WORKDIR /usr/local
RUN yum -y update && yum install -y \
    gcc make zlib-devel libffi-devel openssl-devel bzip2-devel ncurses-devel sqlite-devel gdbm-devel xz-devel tk-devel readline-devel  && \
    wget https://www.python.org/ftp/python/3.7.12/Python-3.7.12.tar.xz && \
    xz -d Python-3.7.12.tar.xz && \
    tar -xvf Python-3.7.12.tar && \
    cd Python-3.7.12 && \
    ./configure --prefix=/usr/local/python3.7 --enable-optimizations && \
    make && make install && \
    ln -s /usr/local/python3.7/bin/python3.7 /usr/bin/python3 && \
    ln -s /usr/local/python3.7/bin/pip3.7 /usr/bin/pip3 && \
    pip3 install --upgrade pip

ENV PATH "/usr/local/python3.7/bin:$PATH"
RUN curl -fSsL -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

RUN pip3 --use-deprecated=html5lib --no-cache-dir install \
    future>=0.17.1 \
    grpcio \
    h5py \
    keras_applications>=1.0.8 \
    keras_preprocessing>=1.1.0 \
    mock \
    numpy \
    portpicker \
    requests \
    --ignore-installed setuptools \
    --ignore-installed six>=1.12.0

ENV BAZEL_VERSION 3.7.2
WORKDIR /
RUN mkdir /bazel && \
    cd /bazel && \
    curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE && \
    chmod +x bazel-*.sh && \
    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    cd / && \
    rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh


# Download TF Serving sources (optionally at specific ccommit).
WORKDIR /tensorflow-serving
RUN curl -sSL --retry 5 https://github.com/tensorflow/serving/tarball/TF_SERVING_VERSION_GIT_BRANCH/${TF_SERVING_VERSION_GIT_COMMIT} | tar --strip-components=1 -xzf -

RUN source /opt/rh/devtoolset-8/enable && \
    BAZEL_LINKLIBS=-l%:libstdc++.a bazel build --color=yes --curses=yes \
    ${TF_SERVING_BAZEL_OPTIONS} \
    --verbose_failures \
    --output_filter=DONT_MATCH_ANYTHING \
    ${TF_SERVING_BUILD_OPTIONS} \
    tensorflow_serving/model_servers:tensorflow_model_server && \
    cp bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server \
    /usr/local/bin/

# Build and install TensorFlow Serving API
RUN source /opt/rh/devtoolset-8/enable && \
    BAZEL_LINKLIBS=-l%:libstdc++.a bazel build --color=yes --curses=yes \
    ${TF_SERVING_BAZEL_OPTIONS} \
    --verbose_failures \
    --output_filter=DONT_MATCH_ANYTHING \
    ${TF_SERVING_BUILD_OPTIONS} \
    tensorflow_serving/tools/pip_package:build_pip_package && \
    bazel-bin/tensorflow_serving/tools/pip_package/build_pip_package \
    /tmp/pip && \
    pip --use-deprecated=html5lib --no-cache-dir install --upgrade \
    /tmp/pip/tensorflow_serving_api-*.whl && \
    rm -rf /tmp/pip

RUN  bazel --batch clean --expunge --color=yes
RUN rm -rf /root/.cache
CMD ["/bin/bash"]

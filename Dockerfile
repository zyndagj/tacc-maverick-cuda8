#Image: gzynda/tacc-maverick-cuda8
#Version: 0.0.2

FROM gzynda/tacc-base:0.0.2

########################################
# Install CUDA runtime
########################################

# https://gitlab.com/nvidia/cuda/blob/ubuntu16.04/8.0/runtime/Dockerfile

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates apt-transport-https gnupg-curl \
    && docker-clean \
    && NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 \
    && NVIDIA_GPGKEY_FPR=ae09fe4bbd223a84b2ccfce3f60f4b3d7fa2af80 \
    && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub \
    && apt-key adv --export --no-emit-version -a $NVIDIA_GPGKEY_FPR | tail -n +5 > cudasign.pub \
    && echo "$NVIDIA_GPGKEY_SUM  cudasign.pub" | sha256sum -c --strict - && rm cudasign.pub \
    && echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list

ENV CUDA_VERSION 8.0.61

ENV CUDA_PKG_VERSION 8-0=$CUDA_VERSION-1
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-nvrtc-$CUDA_PKG_VERSION \
        cuda-nvgraph-$CUDA_PKG_VERSION \
        cuda-cusolver-$CUDA_PKG_VERSION \
        cuda-cublas-8-0=8.0.61.2-1 \
        cuda-cufft-$CUDA_PKG_VERSION \
        cuda-curand-$CUDA_PKG_VERSION \
        cuda-cusparse-$CUDA_PKG_VERSION \
        cuda-npp-$CUDA_PKG_VERSION \
        cuda-cudart-$CUDA_PKG_VERSION \
    && ln -s cuda-8.0 /usr/local/cuda \
    && docker-clean

# nvidia-docker 1.0
LABEL com.nvidia.volumes.needed="nvidia_driver"
LABEL com.nvidia.cuda.version="${CUDA_VERSION}"

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=8.0"

########################################
# Install CUDA development
########################################

RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-core-$CUDA_PKG_VERSION \
        cuda-misc-headers-$CUDA_PKG_VERSION \
        cuda-command-line-tools-$CUDA_PKG_VERSION \
        cuda-nvrtc-dev-$CUDA_PKG_VERSION \
        cuda-nvml-dev-$CUDA_PKG_VERSION \
        cuda-nvgraph-dev-$CUDA_PKG_VERSION \
        cuda-cusolver-dev-$CUDA_PKG_VERSION \
        cuda-cublas-dev-8-0=8.0.61.2-1 \
        cuda-cufft-dev-$CUDA_PKG_VERSION \
        cuda-curand-dev-$CUDA_PKG_VERSION \
        cuda-cusparse-dev-$CUDA_PKG_VERSION \
        cuda-npp-dev-$CUDA_PKG_VERSION \
        cuda-cudart-dev-$CUDA_PKG_VERSION \
        cuda-driver-dev-$CUDA_PKG_VERSION \
    && docker-clean

ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs:${LIBRARY_PATH}
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64/stubs:${LD_LIBRARY_PATH}

########################################
# Install cuDNN
########################################

RUN echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

ENV CUDNN_VERSION 7.1.4.18
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
            libcudnn7=$CUDNN_VERSION-1+cuda8.0 \
            libcudnn7-dev=$CUDNN_VERSION-1+cuda8.0 && \
    docker-clean

########################################
# Install mpi
########################################

# necessities and IB stack
RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
        curl gfortran bison libibverbs-dev libibmad-dev libibumad-dev librdmacm-dev libmlx5-dev libmlx4-dev && \
    docker-clean

# Install mvapich2-2.2
ARG MAJV=2
ARG MINV=2
ARG DIR=mvapich${MAJV}-${MAJV}.${MINV}

RUN curl http://mvapich.cse.ohio-state.edu/download/mvapich/mv${MAJV}/${DIR}.tar.gz | tar -xzf - \
    && cd ${DIR} \
    && ./configure \
    && make -j $(nproc --all 2>/dev/null || echo 2) && make install \
    && mpicc examples/hellow.c -o /usr/bin/hellow \
    && cd ../ && rm -rf ${DIR}

ARG CUDA=11.7.1
ARG CONDA_RELEASE=23.3.1-1
ARG TOOL_NAME="diffdock"
ARG TOOL_VERSION="v1.1.2"

####################################
# Stage 1: Build Environment Setup #
####################################
FROM docker.io/nvidia/cuda:${CUDA}-devel-ubuntu22.04 AS builder

# FROM directive resets ARGS, so we specify again (the value is retained if
# previously set).
ARG CUDA
ARG CONDA_RELEASE
ARG TOOL_NAME
ARG TOOL_VERSION

# Use bash to support string substitution.
SHELL ["/bin/bash", "-oue", "pipefail", "-c"]

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        wget curl git tar bzip2 unzip \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && apt-get clean

# Install Miniconda package manager.
RUN wget -P /tmp \
    "https://github.com/conda-forge/miniforge/releases/download/${CONDA_RELEASE}/Miniforge3-Linux-x86_64.sh" \
    && bash /tmp/Miniforge3-Linux-x86_64.sh -b -p /opt/conda \
    && rm /tmp/Miniforge3-Linux-x86_64.sh

# Install conda packages.
ENV PATH="/opt/conda/bin:$PATH"

# Install conda environment
COPY environment-${TOOL_VERSION}.yml environment-${TOOL_VERSION}.yml 
RUN mamba env update --file environment-${TOOL_VERSION}.yml --prefix /opt/conda/envs/${TOOL_NAME} \
 && mamba clean --all

# Activate the conda environment
RUN  mkdir -p /opt/etc \
  && /bin/echo -e "#! /bin/bash\n\n# script to activate the conda environment ${TOOL_NAME}" > ~/.bashrc \
  && conda init bash \
  && /bin/echo "conda activate ${TOOL_NAME}" >> ~/.bashrc \
  && cp ~/.bashrc /opt/etc/bashrc 

# Launch interactive bash session to read ~/.bashrc
SHELL ["/bin/bash","-oue", "pipefail", "-i", "-c"]

# Install pip dependencies
COPY requirements-${TOOL_VERSION}-step1.txt requirements-${TOOL_VERSION}-step1.txt
COPY requirements-${TOOL_VERSION}-step2.txt requirements-${TOOL_VERSION}-step2.txt
RUN pip install -r requirements-${TOOL_VERSION}-step1.txt \
  && pip install -r requirements-${TOOL_VERSION}-step2.txt \
  && pip cache purge

################################
# Stage 2: Runtime Environment #
################################
FROM docker.io/nvidia/cuda:${CUDA}-runtime-ubuntu22.04

ARG TOOL_NAME="diffdock"

COPY --from=builder /opt/ /opt/
COPY . /app/${TOOL_NAME}
ENV PATH="/opt/conda/bin:$PATH"

# Use bash to support string substitution.
SHELL ["/bin/bash", "-oue", "pipefail", "-c"]

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && apt-get clean

SHELL ["/bin/bash", "-o", "pipefail", "-c"]


# Create folder need by torch and diffdock models
RUN mkdir /app/${TOOL_NAME}/torch_home /app/${TOOL_NAME}/workdir 

# Add version using github tag
COPY version-info.txt /app/${TOOL_NAME}/version-info.txt

# Add SETUID bit to the ldconfig binary so that non-root users can run it.
RUN chmod u+s /sbin/ldconfig.real

# We need to run `ldconfig` first to ensure GPUs are visible, due to some quirk
# with Debian. See https://github.com/NVIDIA/nvidia-docker/issues/1399 for
# details.
# ENTRYPOINT does not support easily running multiple commands, so instead we
# write a shell script to wrap them up.
WORKDIR /app/${TOOL_NAME}
RUN echo -e $"#!/bin/bash\n\
ldconfig -C ld.so.cache\n\
source /opt/etc/bashrc\n\
export TORCH_HOME=/app/${TOOL_NAME}/torch_home\n\
python /app/${TOOL_NAME}/inference.py \"\$@\"" > "/app/launch_${TOOL_NAME}.sh" \
  && chmod +x "/app/launch_${TOOL_NAME}.sh" \
  && echo -e $"#!/bin/bash\n\
cat /app/${TOOL_NAME}/version-info.txt" > /app/get_version.sh \
  && chmod +x /app/get_version.sh

ENV LC_ALL C
ENV PATH /opt/conda/bin:/usr/local/cuda-11.7/bin:/usr/local/bin/$PATH
ENV PATH $PATH:/app
ENV BASH_ENV /opt/etc/bashrc


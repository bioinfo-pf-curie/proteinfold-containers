# Copyright 2021 DeepMind Technologies Limited
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG CUDA=11.7.1
ARG CONDA_RELEASE=23.3.1-1
FROM docker.io/nvidia/cuda:${CUDA}-cudnn8-runtime-ubuntu20.04
# FROM directive resets ARGS, so we specify again (the value is retained if
# previously set).
ARG CUDA
ARG CONDA_RELEASE

# Use bash to support string substitution.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        cuda-command-line-tools-$(cut -f1,2 -d- <<< ${CUDA//./-}) \
        wget \
        patch \
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

# Install conda environment for structural DynamicBind
COPY environment.yml environment.yml 
COPY dynamicbind-v1.0-nodefaults.patch dynamicbind-v1.0-nodefaults.patch 
RUN patch -p1 < dynamicbind-v1.0-nodefaults.patch
RUN mamba env update --file environment.yml --prefix /opt/conda/envs/dynamicbind \
 && mamba clean --all

# Install conda environment for structural relaxation
COPY dynamicbind-relax-nodefaults.yml dynamicbind-relax-nodefaults.yml 
RUN mamba env update --file dynamicbind-relax-nodefaults.yml --prefix /opt/conda/envs/relax \
 && mamba clean --all

RUN ln -s /opt/conda/envs/relax/bin/python /usr/local/bin/python_relax

# Activate the conda environment
RUN  mkdir -p /opt/etc \
  && /bin/echo -e "#! /bin/bash\n\n# script to activate the conda environment dynamicbind" > ~/.bashrc \
  && conda init bash \
  && /bin/echo "conda activate dynamicbind" >> ~/.bashrc \
  && cp ~/.bashrc /opt/etc/bashrc 


# Get rid of the following message by upgrading numpy
# Error: mkl-service + Intel(R) MKL: MKL_THREADING_LAYER=INTEL is incompatible with libgomp.so.1 library.
#         Try to import numpy first or set the threading layer accordingly. Set MKL_SERVICE_FORCE_INTEL to force it.
SHELL ["/bin/bash", "--login", "-c"]
RUN pip install -U numpy==1.26.4

COPY . /app/dynamicbind

# Add SETUID bit to the ldconfig binary so that non-root users can run it.
RUN chmod u+s /sbin/ldconfig.real

# Add version using github tag
COPY version-info.txt /app/dynamicbind/version-info.txt

# We need to run `ldconfig` first to ensure GPUs are visible, due to some quirk
# with Debian. See https://github.com/NVIDIA/nvidia-docker/issues/1399 for
# details.
# ENTRYPOINT does not support easily running multiple commands, so instead we
# write a shell script to wrap them up.
WORKDIR /app/dynamicbind
RUN echo $'#!/bin/bash\n\
ldconfig\n\
source /opt/etc/bashrc \n\
python /app/dynamicbind/run_single_protein_inference.py "$@"' > /app/run_dynamicbind.sh \
  && chmod +x /app/run_dynamicbind.sh
ENTRYPOINT ["/app/run_dynamicbind.sh"]

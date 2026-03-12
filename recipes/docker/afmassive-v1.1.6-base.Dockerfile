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

ARG CUDA=11.2.2
ARG CONDA_RELEASE=py38_23.11.0-1
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
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && apt-get clean


# Install Miniconda package manager.
RUN wget -q -P /tmp \
  https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_RELEASE}-Linux-x86_64.sh \
    && bash /tmp/Miniconda3-${CONDA_RELEASE}-Linux-x86_64.sh -b -p /opt/conda \
    && rm /tmp/Miniconda3-${CONDA_RELEASE}-Linux-x86_64.sh

# Install conda packages.
ENV PATH="/opt/conda/bin:$PATH"

COPY . /app/alphafold
RUN wget -q -P /app/alphafold/alphafold/common/ \
  https://git.scicore.unibas.ch/schwede/openstructure/-/raw/7102c63615b64735c4941278d92b554ec94415f8/modules/mol/alg/src/stereo_chemical_props.txt

# Install conda dependencies
RUN sed -i "0,/defaults/s/defaults/nodefaults/" /app/alphafold/environment.yml
RUN sed -i "0,/setuptools/s/setuptools/setuptools=80.10.2/" /app/alphafold/environment.yml
RUN conda env create -f "/app/alphafold/environment.yml" && conda clean --all --force-pkgs-dirs --yes


# Add SETUID bit to the ldconfig binary so that non-root users can run it.
RUN chmod u+s /sbin/ldconfig.real

# Add version using github tag
COPY version-info.txt /app/alphafold/version-info.txt

# We need to run `ldconfig` first to ensure GPUs are visible, due to some quirk
# with Debian. See https://github.com/NVIDIA/nvidia-docker/issues/1399 for
# details.
# ENTRYPOINT does not support easily running multiple commands, so instead we
# write a shell script to wrap them up.
WORKDIR /app/alphafold
RUN mkdir /opt/etc
RUN echo $'#!/bin/bash\n\
ldconfig\n\
source /opt/etc/bashrc \n\
python /app/alphafold/run_AFmassive.py "$@"' > /app/run_afMassive.sh \
  && chmod +x /app/run_afMassive.sh \
  && /bin/echo -e '#! /bin/bash\n\n# script to activate the conda environment' > ~/.bashrc \
  && /opt/conda/bin/conda init bash \
  && echo 'conda activate AFmassive-1.1.6' >> ~/.bashrc \
  && cp ~/.bashrc /opt/etc/bashrc
ENV BASH_ENV=/opt/etc/bashrc
ENTRYPOINT ["/app/run_afMassive.sh"]

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

FROM ubuntu:24.04

RUN apt update && apt install -y patch wget imagemagick

ARG CONDA_RELEASE=23.3.1-1

# Use bash to support string substitution.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Miniconda package manager.
RUN wget -P /tmp \
"https://github.com/conda-forge/miniforge/releases/download/${CONDA_RELEASE}/Miniforge3-Linux-x86_64.sh" \
&& bash /tmp/Miniforge3-Linux-x86_64.sh -b -p /opt/conda \
&& rm /tmp/Miniforge3-Linux-x86_64.sh

# Install conda packages.
ENV PATH="/opt/conda/bin:$PATH"

RUN mkdir /opt/etc

COPY . /app/AlphaBridge

WORKDIR /app/AlphaBridge

RUN patch -p1 < alphabridge-v0.0.2-base.patch

RUN /opt/conda/bin/conda env create -f environment.yml -n AlphaBridge

RUN /bin/echo -e '#! /bin/bash\n\
source /opt/etc/bashrc \n\
python /app/AlphaBridge/define_interfaces.py "$@"' > /app/define_interfaces.sh \
&& chmod +x /app/define_interfaces.sh \
&& /bin/echo -e '#! /bin/bash\ncat /app/AlphaBridge/version-info.txt' > /app/get_version.sh \
&& chmod +x /app/get_version.sh \
&& /bin/echo -e '#! /bin/bash\n\n# script to activate the conda environment AlphaBridge' > ~/.bashrc \
&& /opt/conda/bin/conda init bash \
&& echo 'conda activate AlphaBridge' >> ~/.bashrc \
&& cp ~/.bashrc /opt/etc/bashrc

ENV LC_ALL C
ENTRYPOINT ["/app/define_interfaces.sh"]

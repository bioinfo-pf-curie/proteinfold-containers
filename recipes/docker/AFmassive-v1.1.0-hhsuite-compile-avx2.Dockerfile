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

FROM docker.io/4geniac/proteinfold/AFmassive-v1.1.0-base AS devel

# Use bash to support string substitution.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      build-essential \
      cmake \
      git

# Compile HHsuite from source.
RUN git clone --branch v3.3.0 https://github.com/soedinglab/hh-suite.git /tmp/hh-suite \
    && mkdir /tmp/hh-suite/build \
    && pushd /tmp/hh-suite/build \
    && cmake -DCMAKE_INSTALL_PREFIX=/opt/hhsuite \
             -DBUILD_SHARED_LIBS=OFF \
             -DCMAKE_EXE_LINKER_FLAGS="-static -static-libgcc -static-libstdc++" \
             -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
             -DHAVE_AVX2=1 \
             -DCHECK_MPI=0 \
        .. \
    && make -j 4 && make install \
    && ln -s /opt/hhsuite/bin/* /usr/bin \
    && popd \
    && rm -rf /tmp/hh-suite

FROM docker.io/4geniac/proteinfold/AFmassive-v1.1.0-base

COPY --from=devel /opt/hhsuite/ /opt/hhsuite/

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      hmmer \
      kalign \
      tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && apt-get clean

RUN ln -s /opt/hhsuite/bin/* /usr/bin

ENTRYPOINT ["/app/run_alphafold.sh"]

FROM ubuntu:24.04 AS devel

RUN apt update \
&& apt install -y libboost-dev zlib1g-dev cmake libeigen3-dev openbabel gcc g++ git

RUN mkdir /install_tmp

COPY . /install_tmp/alphafill/

RUN cd /install_tmp/alphafill \
&& cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
&& cmake --build build \
&& cmake --install build

RUN rm -rf /install_tmp

FROM ubuntu:24.04

RUN apt update \
&& apt install -y libboost-dev zlib1g-dev libeigen3-dev openbabel

RUN mkdir -p /app/alphafill/database/pdb-redo/mmcif_files \
&& mkdir -p /app/alphafill/database/pdb-redo/fasta 

COPY version-info.txt /app/alphafill/version-info.txt
COPY --from=devel /usr/local /usr/local

# The setting below implies to start docker with the volume:
# - /app/alphafill/database/pdb-redo/mmcif_files
#   * this folders contains the data collected by the command: rsync -avP --exclude=attic rsync://rsync.pdb-redo.eu/pdb-redo/ mmcif_files
# - /app/alphafill/database/pdb-redo/fasta
#  	* this folder contains the fasta file created by the command: alphafill create-index --pdb-dir mmcif_files --pdb-fasta pdb-redo.fasta

RUN sed -i -e 's|pdb-dir=<NEEDS_TO_BE_CHANGED>/pdb-redo/|pdb-dir=/app/alphafill/database/pdb-redo/mmcif_files|g' /usr/local/etc/alphafill.conf \
&& sed -i -e 's|pdb-fasta=<NEEDS_TO_BE_CHANGED>/pdb-redo.fa|pdb-fasta=/app/alphafill/database/pdb-redo/fasta/pdb-redo.fasta|g' /usr/local/etc/alphafill.conf


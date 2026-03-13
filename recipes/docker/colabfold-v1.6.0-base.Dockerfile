FROM ghcr.io/sokrypton/colabfold:1.6.0-cuda12

# Install ps for nextflow
RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*

# Add version using github tag
RUN mkdir -p /app/colabfold
COPY version-info.txt /app/colabfold/version-info.txt

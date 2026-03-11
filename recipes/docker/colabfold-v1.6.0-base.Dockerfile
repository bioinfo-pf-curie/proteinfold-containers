FROM ghcr.io/sokrypton/colabfold:1.6.0-cuda12

# Add version using github tag
RUN mkdir -p /app/colabfold
COPY version-info.txt /app/colabfold/version-info.txt

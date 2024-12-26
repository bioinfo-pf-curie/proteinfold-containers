FROM ghcr.io/sokrypton/colabfold:1.5.5-cuda12.2.2

# Add version using github tag
RUN mkdir -p /app/colabfold
COPY version-info.txt /app/colabfold/version-info.txt

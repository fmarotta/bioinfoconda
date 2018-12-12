FROM ubuntu:18.04

# Set the default shell
SHELL ["/bin/bash", "-c"]

# Add the docker:bioinfo user
RUN addgroup --gid 5000 bioinfo \
    && yes | adduser --quiet --disabled-password \
        --no-create-home --gid 5000 docker

# Install base system utils
RUN apt-get update && apt-get install -y \
        gawk \
        locales \
        python \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Set the locale
RUN locale-gen en_US.UTF-8 \
    && update-locale LANG="en_US.UTF-8" \
    && update-locale LANGUAGE="en_US.UTF-8"

# Replicate xavier's directory structure in the image
RUN mkdir -p /bioinfo/bioinfotree \
        /bioinfo/data \
        /bioinfo/prj

# Add bioinfotree tools
COPY bioinfotree /bioinfo/bioinfotree

# Install miniconda3
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /bioinfo/Miniconda3-latest-Linux-x86_64.sh \
    && bash /bioinfo/Miniconda3-latest-Linux-x86_64.sh -b -p /bioinfo/miniconda3 \
    && rm /bioinfo/Miniconda3-latest-Linux-x86_64.sh

# Set permissions
RUN chown -R root:bioinfo /bioinfo \
    && chmod -R 2775 /bioinfo

# Add bioinfotree's and miniconda's executables to $PATH
ENV PATH="/bioinfo/bioinfotree/local/bin:/bioinfo/miniconda3/bin:$PATH" \
    PYTOHNPATH="/bioinfo/bioinfotree/local/lib/python" \
    PERL5LIB="/bioinfo/bioinfotree/local/lib/perl" \
    LC_ALL="en_US.UTF8" \
    BIOINFO_ROOT="/bioinfo"

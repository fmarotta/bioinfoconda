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
	git \
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
RUN chown -R docker:bioinfo /bioinfo \
    && chmod -R 2775 /bioinfo

# Add bioinfotree's and miniconda's executables to $PATH
ENV PATH="/bioinfo/bioinfotree/local/bin:/bioinfo/miniconda3/bin:$PATH" \
    PYTOHNPATH="/bioinfo/bioinfotree/local/lib/python" \
    PERL5LIB="/bioinfo/bioinfotree/local/lib/perl" \
    LC_ALL="en_US.UTF8" \
    BIOINFO_ROOT="/bioinfo"

# NOTES ON OCCAM
#
# On occam, when we run an image the user is emariell:emariell. When whe 
# build the image, the user is root (or the one specified with the 
# "USER" directive in the dockerfile). The umask cannot be set (unless 
# we set it with a script), so the new files created under /bioinfo will 
# not be writable by the group. Given all this, I think that the most 
# economic option is to chmod 777 everything.
# 
# Setting the workdir does not work on occam, either. We have to 
# manually cd into the required directory.
#
# PYTHONPATH and PERL5LIB must be reset in the project dockerfile to 
# include the bioinfotree libraries. Appending the old variables does 
# not work, but maybe there is a right way to append variables for 
# dockerfiles. I should investigate about that.

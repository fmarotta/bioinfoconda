# Use the bioinfoconda parent image
# NOTE: you should set a version tag!
FROM cbuatmbc/bioinfoconda

# Copy the project directory into the container
# NOTE: remember to add the Snakefiles to the .dockerignore
COPY . {{prjpath}}

# Create the conda environment from the yml file
# NOTE: remember to export the environment before building the image
RUN conda env create -f {{prjpath}}/local/ymlfiles/{{prjname}}.yml

RUN chown -R root:bioinfo /bioinfo 		&& chmod -R 2775 /bioinfo

# Set up the environment
ENV PATH="{{minicondapath}}/envs/{{prjname}}/bin:{{prjpath}}/local/bin:\$PATH" \
	PERL5LIB="{{prjpath}}/local/lib/perl:$PERL5LIB" \
	PERL_CPANM_HOME="{{prjpath}}/local/builds/perl5" \
	PERL_CPANM_OPT="-l {{prjpath}}/local --no-man-pages --save-dists={{prjpath}}/local/src/perl5" \
	PYTHONPATH="{{prjpath}}/local/lib/python:$PYTHONPATH" \
	R_PROFILE_USER="{{prjpath}}/.Rprofile" \
	CONDA_DEFAULT_ENV="{{prjname}}" \
	CONDA_PREFIX="{{minicondapath}}/envs/{{prjname}}"

# WORKDIR /bioinfo/prj/integrated_twas/dataset
# USER docker:bioinfo

# Establish the entry point
ENTRYPOINT ["{{prjpath}}/local/dockerfiles/docker-entrypoint.sh"]
CMD ["snakemake --dag | dot -Tsvg > dag.svg"]

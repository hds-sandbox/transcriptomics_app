# Transcriptomics Ucloud app

This repository contains the necessary materials to create a Docker container that will host the Transcriptomics app in UCloud. The app is created and maintained by the Center for Health Data Science (HeaDS), University of Copenhagen. The app is designed to provide a user-friendly interface (jupyterlab-based) for running RNAseq and single cell analysis pipelines, as well as for exploring and visualizing transcriptomics data.

The Dockerfile will create three Environments, one for working in the command line to create your own RNAseq pipelines with snakemake and jupyter and another one to work with the single cell interactive browser [Cirrocumulus](https://cirrocumulus.readthedocs.io/en/latest/). In addition, it will gives the option to download course materials to run an [introductory workshop to bulk RNAseq](https://hds-sandbox.github.io/bulk_RNAseq_course/), [introductory workshop to scRNAseq](https://hds-sandbox.github.io/scRNASeq_course/), [introductory workshop to spatial transcriptomics](https://hds-sandbox.github.io/intro-spatial-scverse_workshop/), Advanced single cell analysis tutorials [workshop on RNAseq pipelines](https://hds-sandbox.github.io/AdvancedSingleCell/).

Documentation for the app can be found [here](./docs/README.md).

The container can also start in a local computer or HPC cluster with either DOcker or Apptainer installedTo start the docker container, make sure you have Docker installed and running. You can build an image and run the container using:

```bash
docker build -t transcriptomics_app:mycomputer . --progress=plain

docker run --rm -it -p 8787:8787 --name app-test transcriptomics_app:mycomputer start-app -c {OPTION} 
```

Where `{OPTION}` is either:

*   "RNAseq_in_Rstudio": This will start a Rstudio browser version with many RNAseq related packages
*   "Cirrocumulus": This will start a Cirrocumulus session
*   "Intro_bulk_RNAseq": This will start a Rstudio browser session with the materials to run the ["Introduction to bulk RNAseq"](https://hds-sandbox.github.io/bulk_RNAseq_course/) workshop.
*   "Intro_scRNAseq_R": This will start a Rstudio browser session with the materials to run the ["Introduction to single cell RNAseq"](https://hds-sandbox.github.io/scRNAseq_course/) workshop.
*   "RNAseq_CLI": This will start a jupyter lab session with a mamba environment with usual packages for RNAseq tools and snakemake, for those who want to build their own pipeline.
*   "Intro_spatial_scverse": This will start a jupyterlab session with the materials to run the ["Introduction to spatial transcriptomics"](https://hds-sandbox.github.io/intro-spatial-scverse_workshop/) workshop.
*   "Advanced_single_cell": This will start a jupyterlab session with the materials to run the ["Advanced single cell analysis"](https://hds-sandbox.github.io/AdvancedSingleCell/) tutorials.

You can find the interactive session at `localhost:8787`. If you cannot use the 8787 port in your system, you can change the port number in the command above and adding the same port number to the start-app script. For example, if you need port 6868 and advanced single cell tutorials, you can run:

```bash
docker run --rm -it -p 6868:6868 --name app-test transcriptomics_app:mycomputer start-app -c Advanced_single_cell -p 6868
```
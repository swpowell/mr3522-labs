FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04

LABEL maintainer="Scott Powell"

ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=jovyan \
    NB_UID=1000 \
    NB_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod +x /usr/local/bin/fix-permissions

ENV DEBIAN_FRONTEND noninteractive
RUN set -x \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
        redis-tools \
        netcat \
        net-tools \
        openssh-client \
        openconnect \
        openvpn \
        wget \
        bzip2 \
        ca-certificates \
        sudo \
        locales \
        fonts-liberation \
        build-essential \
        emacs \
        git \
        inkscape \
        jed \
        libsm6 \
        libxext-dev \
        libxrender1 \
        lmodern \
        pandoc \
        python-dev \      
        vim \
        curl \
        wget \
        unzip \
        gdal-bin libgdal-dev python3-gdal \
    && wget https://blink.ucsd.edu/_files/technology-tab/network/vpn_install-4.6.01098.sh \
    && wget https://downloads.rclone.org/rclone-current-linux-amd64.deb -O /tmp/rclone-current-linux-amd64.deb \
    && apt install /tmp/rclone-current-linux-amd64.deb \
    && rm -f /tmp/rclone-current-linux-amd64.deb \

    && apt-get install -y apt-transport-https \
    && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list \
    && sudo apt-get update \
    && sudo apt-get install -y kubectl \

    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN set -x \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen

RUN set -x \
    && useradd -m -s /bin/bash -N -u $NB_UID $NB_USER \
    && mkdir -p $CONDA_DIR \
    && chown $NB_USER:$NB_GID $CONDA_DIR \
    && fix-permissions $HOME \
    && fix-permissions $CONDA_DIR

USER $NB_USER

RUN set -x \
    && mkdir /home/$NB_USER/work \
    && fix-permissions /home/$NB_USER

ENV MINICONDA_VERSION 4.7.10
RUN set -x \
    && cd /tmp \
    && wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh \
    && echo "1c945f2b3335c7b2b15130b1b2dc5cf4 *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - \
    && /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR \
    && rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh \
    && $CONDA_DIR/bin/conda config --system --prepend channels conda-forge \
    && $CONDA_DIR/bin/conda config --system --set auto_update_conda false \
    && $CONDA_DIR/bin/conda config --system --set show_channel_urls true \
    && $CONDA_DIR/bin/conda update --only-deps conda --quiet --yes \
    && conda clean --all -y \
    && fix-permissions $CONDA_DIR

RUN set -x \
    && conda install --quiet --yes -c pytorch -c rapidsai -c nvidia -c fastai -c conda-forge \
        'notebook=6.0.*' \
        'jupyterhub=1.0.*' \
        'jupyterlab=1.0.*' \
        'nomkl' \
        'ipywidgets=7.5*' \
        'pandas=0.24*' \
        'numexpr=2.6*' \
        'matplotlib=2.2*' \
        'scipy=1.3*' \
        'seaborn=0.9*' \
        'scikit-learn=0.21*' \
        'scikit-image=0.15*' \
        'sympy=1.4*' \
        'cython=0.29*' \
        'patsy=0.5*' \
        'statsmodels=0.9*' \
        'cloudpickle=0.5*' \
        'dill=0.2*' \
        'numba=0.45*' \
        'bokeh=1.1*' \
        'sqlalchemy=1.3*' \
        'hdf5=1.10.*' \
        'h5py=2.9*' \
        'vincent=0.4.*' \
        'beautifulsoup4=4.7*' \
        'protobuf=3.*' \
        'jupyter_contrib_nbextensions' \
        'xlrd' \
        'astropy' \
        'numpy' \
        'boto3' \
        'netcdf4' \
        'r-irkernel' \
        'python-dotenv' \
        'sqlalchemy' \
        'xgboost' \
        'psycopg2' \
        'cudf=0.9' 'cuml=0.9' 'cugraph=0.9' \
        'fastai' \
        'bowtie-py' \
    && conda remove --quiet --yes --force qt pyqt \
    && conda clean --all -y \
    && pip install \
        argparse \
        imutils \
        keras==2.2.5 \
        nbgitpuller \
        opencv-python \
        requests \
        tensorflow-gpu==2.1.0 \
        torch \
        torchvision \
        visualdl==1.3.0 \
        git+https://github.com/veeresht/CommPy.git \
        tensorflow-probability \
        bash_kernel \
        matlab_kernel \
        pygdal==2.2.3.3 \
    && python -m bash_kernel.install \
    && jupyter nbextension enable --py widgetsnbextension --sys-prefix \
    && jupyter labextension install @jupyterlab/hub-extension \
    && jupyter serverextension enable --py nbgitpuller --sys-prefix \
    && fix-permissions $CONDA_DIR


USER root

EXPOSE 8888
WORKDIR $HOME

ENTRYPOINT ["jupyter-labhub"]

COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/
RUN fix-permissions /etc/jupyter/

RUN cd /tmp && \
    git clone https://github.com/PAIR-code/facets.git && \
    cd facets && \
    jupyter nbextension install facets-dist/ --sys-prefix && \
    rm -rf facets && \
    fix-permissions $CONDA_DIR

ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions /home/$NB_USER

RUN echo "jovyan ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -aG sudo jovyan && \
    usermod -aG root jovyan

USER $NB_USER



FROM sharelatex/sharelatex:5.2.1

SHELL ["/bin/bash", "-cx"]

# Update TeX Live manager and install full scheme
RUN wget "https://mirror.ctan.org/systems/texlive/tlnet/update-tlmgr-latest.sh" \
    && sh update-tlmgr-latest.sh \
    && rm update-tlmgr-latest.sh \
    && tlmgr --version \
    && tlmgr update texlive-scripts \
    && tlmgr update --all \
    && tlmgr install scheme-full \
    && tlmgr path add

# Install system packages and enable shell-escape
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y inkscape lilypond \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && TEXLIVE_FOLDER=$(find /usr/local/texlive/ -type d -name '20*') \
    && echo "% enable shell-escape by default" >> /$TEXLIVE_FOLDER/texmf.cnf \
    && echo "shell_escape = t" >> /$TEXLIVE_FOLDER/texmf.cnf

FROM sharelatex/sharelatex:5.2.1

SHELL ["/bin/bash", "-cx"]

RUN wget "https://mirror.ctan.org/systems/texlive/tlnet/update-tlmgr-latest.sh" \
    && sh update-tlmgr-latest.sh \
    && tlmgr --version

RUN tlmgr update texlive-scripts 

RUN tlmgr update --all

RUN tlmgr install scheme-full

RUN tlmgr path add

RUN apt-get update && apt-get upgrade -y

RUN apt-get install inkscape -y

RUN apt-get install lilypond -y

RUN TEXLIVE_FOLDER=$(find /usr/local/texlive/ -type d -name '20*') \
    && echo % enable shell-escape by default >> /$TEXLIVE_FOLDER/texmf.cnf \
    && echo shell_escape = t >> /$TEXLIVE_FOLDER/texmf.cnf

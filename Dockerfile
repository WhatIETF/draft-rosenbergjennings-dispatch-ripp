#
# To build the docker images run
#   docker build -t fluffy/rfc .
# To build the drafts, run
#   docker run --mount type=bind,source="$(pwd)",destination=/data fluffy/rfc 
# To debug docker run
#   docker run -i --mount type=bind,source="$(pwd)",destination=/data  fluffy/rfc /bin/tcsh
#

FROM ubuntu:latest
LABEL maintainer="fluffy@iii.ca"
LABEL description="Docker to build RFC"

RUN  apt -y update
RUN  apt -y upgrade

RUN apt install -y tcsh  

RUN apt install -y golang python git

RUN apt install -y python3-pip

RUN apt install -y python3-pip

RUN pip3 install --upgrade pip

RUN pip3 install xml2rfc 

#RUN mkdir -p /var/cache/xml2rfc

RUN mkdir -p /tmp/go
ENV GOPATH /tmp/go

RUN git clone --branch=master https://github.com/miekg/mmark.git /tmp/go/src/github.com/miekg/mmark 
RUN cd /tmp/go/src/github.com/miekg/mmark/ && go get && go build && cd mmark && go build && cp ./mmark /usr/bin/mmark


RUN apt install -y nodejs npm 

RUN npm i -g raml2html
RUN npm i -g raml2html-markdown-theme

RUN mkdir -p /data

WORKDIR /data

CMD make 

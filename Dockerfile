FROM node:6.7

ENV TMPDIR /tmp
RUN npm config set unsafe-perm true
RUN npm install -g elm@0.18.0

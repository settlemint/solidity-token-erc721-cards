FROM node:20.14.0-bookworm as dependencies

RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
  export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -y --no-install-recommends build-essential jq python3 libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev git  && \
  npm install -g pnpm@latest

ENV FOUNDRY_DIR /usr/local
RUN curl -L https://foundry.paradigm.xyz | bash && \
  /usr/local/bin/foundryup

WORKDIR /

COPY . /usecase

WORKDIR /usecase

USER root

RUN npm install
RUN forge build
RUN npx hardhat compile

WORKDIR /usecase

COPY --from=build /usecase /usecase
COPY --from=build /root/.svm /usecase-svm
COPY --from=build /root/.cache /usecase-cache

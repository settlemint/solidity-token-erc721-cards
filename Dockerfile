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

# Final stage
FROM node:20.13.1-bookworm

# Install necessary runtime dependencies
RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
  export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -y --no-install-recommends libcairo2 libpango-1.0-0 libjpeg62-turbo libgif7 librsvg2-2 git

# Set working directory
WORKDIR /usecase

# Copy the built artifacts from the build stage
COPY --from=build /usecase /usecase
COPY --from=build /root/.svm /usecase-svm
COPY --from=build /root/.cache /usecase-cache

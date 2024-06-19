FROM node:20.14.0-bookworm as build

RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
  export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -y --no-install-recommends build-essential jq python3 libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev git

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

# Second stage: Final image with dependencies
FROM debian:bookworm-20230919-slim

# Install the required libraries in the final image
RUN --mount=type=cache,sharing=locked,target=/var/cache/apt \
  export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -y --no-install-recommends build-essential jq python3 libcairo2 libcairo2-dev libpango1.0-0 libpango1.0-dev libjpeg62-turbo libjpeg-dev libgif7 libgif-dev librsvg2-2 librsvg2-dev git

# Ensure libraries are linked properly
RUN ldconfig

# Debug step: check if libcairo2 is installed
RUN ldconfig -p | grep libcairo

# Copy the application from the build stage
COPY --from=build /usecase /usecase
COPY --from=build /root/.svm /usecase-svm
COPY --from=build /root/.cache /usecase-cache

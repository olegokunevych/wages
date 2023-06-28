###################
# Build container #
###################
FROM elixir:1.15-otp-24-alpine as build

ARG MIX_ENV=prod
ARG SERVICE_PORT=4000

# Dependencies
RUN apk add --no-cache git libgcc make gcc libc-dev openssl openssl-dev nodejs npm

# Setup tools
RUN mix local.hex --force && \
    mix local.rebar --force

# Import applications and tools
COPY . .

# Compile assets
# RUN npm install --prefix ./assets --legacy-peer-deps
# RUN npm rebuild node-sass ./assets

# Generate release
WORKDIR /
RUN mix deps.get --only ${MIX_ENV} && \
    mix release --overwrite --path=artifact

# RUN npm run deploy --prefix ./assets
# RUN mix phx.digest
RUN mix assets.setup
RUN mix assets.build

########################
# Deployable container #
########################
FROM alpine:3.17.2

ARG NET_DEVICE=eth0
# TODO Replace with your application name
ARG RELEASE_NAME=wages
ARG RELEASE_VERSION=0.3.1
ARG SERVICE_PORT=4000

RUN apk --no-cache add ca-certificates ncurses-libs libcrypto1.1 libgcc libstdc++ libssl1.1 openssl-dev ncurses-libs ncurses-terminfo-base ncurses-terminfo

WORKDIR /
COPY --from=build /artifact /artifact
COPY --from=build /priv/static "/artifact/lib/${RELEASE_NAME}-${RELEASE_VERSION}/priv/static"

EXPOSE ${SERVICE_PORT}

ENV NET_DEVICE=${NET_DEVICE}
ENV RELEASE_NAME=${RELEASE_NAME}
ENV SERVICE_PORT=${SERVICE_PORT}

RUN echo "/artifact/bin/${RELEASE_NAME} eval 'Wages.ReleaseTasks.migrate()'" > start.sh
RUN echo "/artifact/bin/${RELEASE_NAME} start" >> start.sh
CMD ["sh", "start.sh"]

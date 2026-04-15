# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_PYTHON_VERSION=0 \
      BUILD_SRC=afairgiant/MediKeep.git \
      BUILD_ROOT=/MediKeep

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin
  FROM 11notes/distroless:localhealth AS distroless-localhealth


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: MEDIKEEP / SOURCE
  FROM alpine AS src
  COPY --from=util-bin / /
  ARG APP_VERSION \
      APP_ROOT \
      BUILD_SRC \
      BUILD_ROOT

  RUN set -ex; \
    eleven apk add git;

  RUN set -ex; \
    eleven git clone ${BUILD_SRC} v${APP_VERSION};


# :: MEDIKEEP / FRONTEND
  FROM node:lts-alpine AS frontend
  ARG BUILD_ROOT
  COPY --from=src ${BUILD_ROOT} ${BUILD_ROOT}
  ENV VITE_API_URL=/api/v1 \
      CI=true \
      GENERATE_SOURCEMAP=false

  RUN set -ex; \
    cd ${BUILD_ROOT}/frontend; \
    rm -f .eslintrc.production.js .eslintrc.js; \
    npm ci --include=optional --silent --no-audit --no-fund; \
    find . -name "*.test.js" -o -name "*.test.jsx" -o -name "*.spec.js" -o -name "*.spec.jsx" | xargs rm -f; \
    rm -rf src/__tests__ src/**/__tests__; \
    CI=false ESLINT_NO_DEV_ERRORS=true DISABLE_ESLINT_PLUGIN=true npm run build; \
    find build -name "*.map" -delete; \
    npm prune --production;


# :: MEDIKEEP / BACKEND
  FROM 11notes/python:${APP_PYTHON_VERSION} AS build
  USER root
  ARG APP_ROOT \
      BUILD_ROOT
  COPY --from=frontend ${BUILD_ROOT}/frontend/build/ /opt${APP_ROOT}/static
  COPY --from=src ${BUILD_ROOT}/shared /opt${APP_ROOT}/shared
  COPY --from=src ${BUILD_ROOT}/app /opt${APP_ROOT}/app
  COPY --from=src ${BUILD_ROOT}/run.py /opt${APP_ROOT}
  COPY --from=src ${BUILD_ROOT}/alembic /opt${APP_ROOT}/alembic
  COPY --from=src ${BUILD_ROOT}/requirements.txt /

  RUN set -ex; \
    pip install \
      --only-binary=:all: \
      -r /requirements.txt;

  RUN set -ex; \
    chmod -R 0755 /opt${APP_ROOT};

  RUN set -ex; \
    apk --update --no-cache add \
      libgcc \
      libpq \
      libjpeg-turbo;


# :: FILE-SYSTEM
  FROM alpine AS file-system
  ARG APP_ROOT
  RUN set -ex; \
    mkdir -p /distroless${APP_ROOT}/var; \
    mkdir -p /distroless${APP_ROOT}/log; \
    mkdir -p /distroless${APP_ROOT}/backup;


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: app specific environment
    ENV DB_HOST="postgres" \
        DB_PORT="5432" \
        DB_NAME="postgres" \
        DB_USER="postgres" \
        STATIC_DIR="/opt${APP_ROOT}/static" \
        UPLOAD_DIR=${APP_ROOT}/var \
        BACKUP_DIR=${APP_ROOT}/backup \
        LOG_DIR=${APP_ROOT}/log \
        LOG_ROTATION_METHOD="python" \
        LOG_ROTATION_BACKUP_COUNT="1" \
        LOG_LEVEL="WARNING"

  # :: multi-stage
    COPY --from=build / /
    COPY --from=distroless-localhealth / /
    COPY --from=file-system --chown=${APP_UID}:${APP_GID} /distroless/ /

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/var","${APP_ROOT}/backup"]

# :: MONITORING
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/localhealth", "http://127.0.0.1:8080/health"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/uvicorn"]
  WORKDIR /opt${APP_ROOT}
  CMD ["app.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "4"]
ARG PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# ------------------------------
# Base
# ------------------------------

FROM node:22-bookworm-slim AS base

ARG PLAYWRIGHT_BROWSERS_PATH

ENV PLAYWRIGHT_BROWSERS_PATH=${PLAYWRIGHT_BROWSERS_PATH}
ENV NODE_ENV=production

WORKDIR /app

# Install production dependencies
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Install Chromium system dependencies
RUN npx playwright-core install-deps chromium


# ------------------------------
# Browser
# ------------------------------

FROM base AS browser

RUN npx playwright-core install --no-shell chromium


# ------------------------------
# Runtime
# ------------------------------

FROM base

ARG PLAYWRIGHT_BROWSERS_PATH
ARG USERNAME=node

ENV NODE_ENV=production
ENV PLAYWRIGHT_BROWSERS_PATH=${PLAYWRIGHT_BROWSERS_PATH}

# Copy Chromium
COPY --from=browser ${PLAYWRIGHT_BROWSERS_PATH} ${PLAYWRIGHT_BROWSERS_PATH}

# Copy application
COPY cli.js package.json ./

# Prepare permissions
RUN chown -R ${USERNAME}:${USERNAME} /app ${PLAYWRIGHT_BROWSERS_PATH}

USER ${USERNAME}

# MCP/SSE listens on Railway's PORT
EXPOSE 8080

# Start Playwright MCP
ENTRYPOINT ["sh", "-c", "node /app/cli.js --headless --browser chromium --no-sandbox --host 0.0.0.0 --port ${PORT} --allowed-hosts '*'"]

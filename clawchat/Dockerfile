FROM oven/bun:1 AS base
WORKDIR /app

# Copy workspace root and install dependencies
COPY package.json bun.lock ./
COPY packages/protocol/package.json packages/protocol/
COPY service/package.json service/
COPY cli/package.json cli/
RUN bun install --frozen-lockfile

# Copy source code
COPY packages/protocol/ packages/protocol/
COPY service/ service/
COPY tsconfig.base.json ./

# Run the relay service
EXPOSE 8787
ENV PORT=8787
ENV DB_PATH=/data/clawchat.db

CMD ["bun", "service/src/index.ts"]

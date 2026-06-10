# Deploy gbrain's MCP HTTP server (Railway, or any Docker host).
# oven/bun guarantees the Bun runtime is present and on PATH — no global
# `gbrain` binary needed; we run the CLI from source the same way `bun run dev` does.
FROM oven/bun:1

WORKDIR /app

# Install deps first for layer caching. node_modules is excluded from the
# build context by .dockerignore, so this installs fresh Linux binaries.
COPY package.json ./
RUN bun install

# Copy the rest of the source.
COPY . .

ENV NODE_ENV=production

# Railway injects $PORT at runtime; fall back to 3131 for local `docker run`.
# Shell form (no JSON array) so ${PORT} actually expands.
# --public-url: the OAuth issuer advertised in discovery metadata MUST be the
#   public deploy URL, not the container's localhost, or remote MCP clients
#   (Claude desktop/web connectors) get redirected to an unreachable host.
#   Set GBRAIN_PUBLIC_URL as a Railway variable so the real address stays out
#   of the (public) repo; falls back to localhost for local `docker run`.
# DCR is intentionally OFF: /authorize auto-approves (no login/consent), and the
#   DCR scope allowlist is hardcoded to include write/agent/admin. With a public
#   URL, --enable-dcr would let any caller self-register a client and mint a
#   write/agent token. Clients are pre-registered via `gbrain auth register-client`.
CMD bun run src/cli.ts serve --http --bind 0.0.0.0 --port ${PORT:-3131} \
  --public-url ${GBRAIN_PUBLIC_URL:-http://localhost:${PORT:-3131}}

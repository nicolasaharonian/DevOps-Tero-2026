# ---------- Etapa 1: compilación ----------
FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn/releases ./.yarn/releases
RUN yarn install --immutable
COPY nest-cli.json tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN yarn build \
 && yarn workspaces focus --production \
 && yarn cache clean --all

# ---------- Etapa 2: ejecución (imagen mínima, sin root) ----------
FROM gcr.io/distroless/nodejs22-debian12:nonroot
WORKDIR /app
ENV NODE_ENV=production \
    PORT=8080
COPY --from=build --chown=nonroot:nonroot /app/node_modules ./node_modules
COPY --from=build --chown=nonroot:nonroot /app/dist ./dist
COPY --from=build --chown=nonroot:nonroot /app/package.json ./
USER nonroot:nonroot
EXPOSE 8080
# La imagen distroless ya tiene node como ENTRYPOINT
CMD ["dist/main.js"]

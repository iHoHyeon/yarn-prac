FROM node:16-alpine AS builder

ENV NODE_ENV production

RUN apk add --no-cache libc6-compat

WORKDIR /usr/src/app

COPY ./ ./

RUN yarn rebuild && yarn build

FROM node:alpine AS runner

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

ENV NODE_ENV production

WORKDIR /usr/src/app

COPY --from=builder /usr/src/app/next.config.js ./
COPY --from=builder /usr/src/app/public ./public
COPY --from=builder /usr/src/app/.next ./.next
COPY --from=builder /usr/src/app/.yarn ./.yarn
COPY --from=builder /usr/src/app/yarn.lock ./yarn.lock
COPY --from=builder /usr/src/app/.yarnrc.yml ./.yarnrc.yml
COPY --from=builder /usr/src/app/.pnp.cjs ./.pnp.cjs
COPY --from=builder /usr/src/app/package.json ./package.json

RUN rm -rf /app/.yarn/unplugged && yarn rebuild
RUN chown -R nextjs:nodejs /app/.next
RUN echo "YARN VERSION IN RUNNER: " && yarn --version

USER nextjs

EXPOSE 3000

ENV NEXT_TELEMETRY_DISABLED 1

CMD ["yarn", "start"]
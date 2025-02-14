# See: docker inspect node:lts-alpine | jq -r ".[0].RepoDigests[0]" 
FROM node:lts-alpine@sha256:2c405ed42fc0fd6aacbe5730042640450e5ec030bada7617beac88f742b6997b

RUN apk add dumb-init

ENV NODE_ENV production
EXPOSE 3000

WORKDIR /usr/src/app
COPY --chown=node:node . .
RUN npm ci --only=production

USER node
# invoke the Node process directly
CMD ["dumb-init", "node", "server.js"]

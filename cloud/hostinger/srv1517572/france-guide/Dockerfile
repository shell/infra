# Stage 1: Optimize images into build/ folder
FROM node:22-alpine AS optimizer

RUN npm install -g sharp-cli

WORKDIR /src
COPY site/ .

# Create build/ directory mirroring images/ structure, converting everything to WebP
RUN find /src/images -type d | while read dir; do \
      mkdir -p "/src/build/$(echo "$dir" | sed 's|^/src/images/\?||')"; \
    done && \
    find /src/images -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.avif' -o -name '*.webp' \) | while read f; do \
      rel=$(echo "$f" | sed 's|^/src/images/||'); \
      dir=$(dirname "$rel"); \
      base=$(echo "$(basename "$rel")" | sed 's/\.[^.]*$//'); \
      npx sharp -i "$f" -o "/src/build/${dir}/${base}.webp" -- resize 1920 --withoutEnlargement --webp quality=80 2>/dev/null || \
      cp "$f" "/src/build/${dir}/${base}.webp"; \
    done

# Stage 2: Serve with nginx
FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/site.conf

# Ensure correct permissions for nginx
RUN chmod -R 755 /usr/share/nginx/html

# Copy HTML and optimized images (originals not needed at runtime)
COPY --from=optimizer /src/index.html /usr/share/nginx/html/
COPY --from=optimizer /src/build /usr/share/nginx/html/build/

# Fix permissions: directories need 755 (traversable), files need 644 (readable)
RUN find /usr/share/nginx/html -type d -exec chmod 755 {} + && \
    find /usr/share/nginx/html -type f -exec chmod 644 {} +

EXPOSE 80

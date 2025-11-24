FROM ruby:3.4

WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install Ruby gems
RUN bundle install --deployment

# Copy application code
COPY . .

# Expose port
EXPOSE 4567

# Run the application
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "4567"]

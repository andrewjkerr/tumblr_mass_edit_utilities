FROM ruby:2.7.5

# Set up `/script` as the working directory.
WORKDIR /script

# Copy our Gemfile & Lockfile over and install gems.
COPY Gemfile Gemfile.lock ./
RUN bundle install

# And, finally, copy our script over.
# Avoid copying over our config and, instead, we'll add the volume later on.
COPY script.rb ./

# Run the dang thing!
CMD ["ruby", "script.rb"]
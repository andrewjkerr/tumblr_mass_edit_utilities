# typed: strict

class Command; end;
class Command::Base; end;
class Command::Base::IterateThroughLikes < Command
  extend T::Sig

  sig {params(options: Options, config: Config, client: TumblrClient, block: T.proc.params(post: Post).void).void}
  def call(options, config, client, &block)
    # make our base query params
    page_query_params = PageQueryParams.new(
      offset: 0
    )

    stats = T.let(Stats.new, Stats)

    response = client.likes(page_query_params)

    begin
      loop do
        # ++ loop_iterations
        stats.loop_iterations += 1
        puts "New interation: #{stats.loop_iterations}" if options.verbose

        # if there are no more posts, break!
        unless response.has_posts?
          puts "No more posts!" if options.verbose
          break
        end

        # += total_posts & += published_posts
        stats.total_posts += response.posts.size

        # Iterate over each post and turn them to private.
        response.posts.each do |post|
          next if should_skip_post?(options, post)

          yield(post)

          # ++ posts_updated
          stats.posts_updated += 1
        end

        # ok, let's move onto the next page if we have one!
        unless response.has_next_page?
          puts "No next page!" if options.verbose
          break
        end

        # update our PageQueryParams to use the page_number that is next
        page_query_params.offset = page_query_params.limit + T.must(page_query_params.offset)

        # andddd get the next response!
        response = client.likes(page_query_params)
      end
    rescue => e
      puts "Ruh roh, we error'd! Printing stats & bailing..."
      stats.print!
      raise
    end

    stats.print!
  end

  sig {params(options: Options, post: Post).returns(T::Boolean)}
  def should_skip_post?(options, post)
    # Convert post.date to a timestamp
    post_date_timestamp = DateTime.parse(post.date).to_time.to_i

    # For likes, we're skipping posts that were published past the start date provided.
    post_date_timestamp > options.beginning_timestamp
  end
end

# typed: strict

class Command; end;
class Command::Base; end;
class Command::Base::IterateThroughPosts < Command
  extend T::Sig

  sig {params(options: Options, config: Config, client: TumblrClient, block: T.proc.params(post: Post).void).void}
  def call(options, config, client, &block)
    # make our base query params
    page_query_params = PageQueryParams.new(
      before: options.beginning_timestamp,
      tumblelog: config.tumblr_blog_url,
    )

    # add tag if we have one
    page_query_params.tag = options.tag unless options.tag.nil?

    stats = T.let(Stats.new, Stats)

    response = client.posts(config.tumblr_blog_url, page_query_params)

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

        # Now, get only the published posts.
        published_posts = response.posts.select do |post|
          post.state === Post::State::PUBLISHED && !should_skip_post?(post)
        end

        # += total_posts & += published_posts
        stats.total_posts += response.posts.size
        stats.published_posts += published_posts.size

        # Iterate over each post and turn them to private.
        published_posts.each do |post|
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
        page_query_params.page_number = response.next_page_number

        # andddd get the next response!
        response = client.posts(config.tumblr_blog_url, page_query_params)
      end
    rescue => e
      puts "Ruh roh, we error'd! Printing stats & bailing..."
      stats.print!
      raise
    end

    stats.print!
  end

  # Check if we need to skip a post due to some fun edge cases.
  sig {params(post: Post).returns(T::Boolean)}
  def should_skip_post?(post)
    # Pinned posts are somehow always returned in this response. :/
    return true if post.is_pinned

    # Any posts before the, uh, creation of Tumblr have a timestamp before the beginning timestamp.
    # ... don't ask. :p
    return true if Date.parse(post.date) <= Date.new(2007, 01, 01)

    false
  end
end

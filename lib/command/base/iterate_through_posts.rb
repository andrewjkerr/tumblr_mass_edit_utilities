# typed: strict

class Command; end;
class Command::Base; end;
class Command::Base::IterateThroughPosts < Command
  extend T::Sig

  # If we see this many pages in a row with zero real (published, non-skipped) posts,
  # assume we've paged past the end of real content (Tumblr keeps returning pinned posts
  # forever) and stop instead of following `next_page_number` indefinitely.
  MAX_CONSECUTIVE_EMPTY_PAGES = T.let(3, Integer)

  # Hard ceiling on total pages fetched, as a last-resort guard against any other
  # pagination bug that isn't caught by the empty-page check above.
  MAX_LOOP_ITERATIONS = T.let(1000, Integer)

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
    consecutive_empty_pages = T.let(0, Integer)

    response = client.posts(config.tumblr_blog_url, page_query_params)

    begin
      loop do
        # ++ loop_iterations
        stats.loop_iterations += 1
        puts "New interation: #{stats.loop_iterations}" if options.verbose

        # safety net: if we've somehow paginated way further than any real blog should
        # have content for, bail instead of looping forever.
        if stats.loop_iterations > MAX_LOOP_ITERATIONS
          puts "Hit max loop iterations (#{MAX_LOOP_ITERATIONS}); stopping to avoid an infinite loop."
          break
        end

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

        # Tumblr always includes the pinned post on every page, so `response.posts` never
        # actually goes empty near the end of a blog's content. Track consecutive pages
        # with no *real* posts so we can detect that stall and stop instead of following
        # `next_page_number` forever.
        if published_posts.empty?
          consecutive_empty_pages += 1
          if consecutive_empty_pages >= MAX_CONSECUTIVE_EMPTY_PAGES
            puts "Hit #{consecutive_empty_pages} pages in a row with no real posts; stopping."
            break
          end
        else
          consecutive_empty_pages = 0
        end

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

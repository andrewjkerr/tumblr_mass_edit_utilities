# typed: strict

class Command::UpdateCommunityLabels < Command
  extend T::Sig

  sig {params(options: Options, config: Config, client: TumblrClient).void}
  def call(options, config, client)
    unless options_valid?(options)
      raise "Community label categories cannot be empty. Run script with --help for valid community label categories."
    end

    # make our base query params
    page_query_params = PageQueryParams.new(
      before: options.beginning_timestamp,
      tumblelog: config.tumblr_blog_url,
    )

    # add tag if we have one
    page_query_params.tag = options.tag unless options.tag.nil?

    p page_query_params

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
        published_posts = response.posts.select {|post| post.state === Post::State::PUBLISHED}

        # += total_posts & += published_posts
        stats.total_posts += response.posts.size
        stats.published_posts += published_posts.size

        # Iterate over each post and turn them to private.
        published_posts.each do |post|
          puts "Updating community labels on post #{post.id} (#{post.post_url})" if options.verbose
          client.edit(config.tumblr_blog_url, post.id, community_label_categories: options.community_label_categories)

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

  sig {params(options: Options).returns(T::Boolean)}
  def options_valid?(options)
    return false if options.community_label_categories.nil?
    true
  end
end
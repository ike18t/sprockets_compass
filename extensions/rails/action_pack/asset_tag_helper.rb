require 'action_view/helpers/asset_tag_helper'
require 'pry'

module ActionView
  module Helpers
    module AssetTagHelper

      def unlocalized_image_path(source)
        compute_public_path(source, 'images')
      end

      def image_path(source, options={})
        logger.debug '*'*50
        logger.debug "image_path: #{source}"
        logger.debug '*'*50
        source.gsub!(/^\//, '')
        extension = source.split('.').pop
        path = compute_public_path(source, 'assets', options.merge(:ext => extension))
        options[:body] ? path + "?body=1" : path
      end
      alias_method :path_to_image, :image_path

      # Overwrite the javascript_path method to use the 'assets' directory
      # instead of the default 'javascripts' (Sprockets will figure it out)
      def javascript_path(source, options={})
        path = compute_public_path(source, 'assets', options.merge(:ext => 'js'))
        options[:body] ? path + "?body=1" : path
      end
      alias_method :path_to_javascript, :javascript_path # aliased to avoid conflicts with a javascript_path named route

      # Overwrite the stylesheet_path method to use the 'assets' directory
      # instead of the default 'stylesheets' (Sprockets will figure it out)
      def stylesheet_path(source, options={})
        path = compute_public_path(source, 'assets', options.merge(:ext => 'css'))
        options[:body] ? path + "?body=1" : path
      end
      alias_method :path_to_stylesheet, :stylesheet_path # aliased to avoid conflicts with a stylesheet_path named route

      # Overwrite the image_tag method to expand sprockets files if
      # debug mode is turned on.  Never cache files (like the default Rails 2.3 does).
      #
      def image_tag(source, options = {})
        options.symbolize_keys!

        options[:src] = path_to_image(source)
        options[:alt] ||= File.basename(options[:src], '.*').split('.').first.to_s.capitalize

        if size = options.delete(:size)
          options[:width], options[:height] = size.split("x") if size =~ %r{^\d+x\d+$}
        end

        if mouseover = options.delete(:mouseover)
          options[:onmouseover] = "this.src='#{image_path(mouseover)}'"
          options[:onmouseout]  = "this.src='#{image_path(options[:src])}'"
        end

        tag("img", options)
      end

      # Overwrite the stylesheet_link_tag method to expand sprockets files if
      # debug mode is turned on.  Never cache files (like the default Rails 2.3 does).
      def stylesheet_link_tag(*sources)
        options = sources.extract_options!.stringify_keys
        debug   = options.key?(:debug) ? options.delete(:debug) : debug_assets?

        sources.map do |source|
          if debug && !(digest_available?(source, 'css')) && (asset = asset_for(source, 'css'))
            asset.to_a.map { |dep| stylesheet_tag(dep.logical_path, { :body => true }.merge(options)) }
          else
            sources.map { |source| stylesheet_tag(source, options) }
          end
        end.uniq.join("\n").html_safe
      end

      # Overwrite the javascript_include_tag method to expand sprockets files if
      # debug mode is turned on.  Never cache files (like the default Rails 2.3 does).
      #
      def javascript_include_tag(*sources)
        options = sources.extract_options!.stringify_keys
        debug   = options.key?(:debug) ? options.delete(:debug) : debug_assets?

        sources.map do |source|
          if debug && !(digest_available?(source, 'js')) && (asset = asset_for(source, 'js'))
            asset.to_a.map { |dep| javascript_src_tag(dep.logical_path, { :body => true }.merge(options)) }
          else
            sources.map { |source| javascript_src_tag(source.to_s, options) }
          end
        end.uniq.join("\n").html_safe
      end

      private

      def javascript_src_tag(source, options)
        body = options.has_key?(:body) ? options.delete(:body) : false
        content_tag("script", "", { "type" => Mime::JS, "src" => path_to_javascript(source, :body => body) }.merge(options))
      end

      def stylesheet_tag(source, options)
        body = options.has_key?(:body) ? options.delete(:body) : false
        tag("link", { "rel" => "stylesheet", "type" => Mime::CSS, "media" => "screen", "href" => html_escape(path_to_stylesheet(source, :body => body)) }.merge(options), false, false)
      end

      def debug_assets?
        Rails.configuration.action_view.debug_sprockets || false
      end

      # Add the the extension +ext+ if not present. Return full URLs otherwise untouched.
      # Prefix with <tt>/dir/</tt> if lacking a leading +/+. Account for relative URL
      # roots. Rewrite the asset path for cache-busting asset ids. Include
      # asset host, if configured, with the correct request protocol.
      def compute_public_path(source, dir, options = {})
        source = source.to_s
        return source if is_uri?(source)

        source = rewrite_extension(source, options[:ext]) if options[:ext]
        source = rewrite_asset_path(source, dir, options)
        logger.debug "1 #{source}"
        source = rewrite_relative_url_root(source, ActionController::Base.relative_url_root)
        logger.debug "2 #{source}"
        source = rewrite_host_and_protocol(source, options[:protocol])
        logger.debug "3 #{source}"
        source
      end

      def rewrite_relative_url_root(source, relative_root_url)
        relative_root_url && !(source =~ Regexp.new("^" + relative_root_url + "/")) ? relative_root_url + source : source
      end

      def has_request?
        @controller.respond_to?(:request)
      end

      def rewrite_host_and_protocol(source, porotocol = nil)
        host = compute_asset_host(source)
        if has_request? && !host.blank? && !is_uri?(host)
          host = @controller.request.protocol + host
        end
        host ? host + source : source
      end

      # Check for a sprockets version of the asset, otherwise use the default rails behaviour.
      def rewrite_asset_path(source, dir, options = {})
        logger.debug "rewriting asset path for #{source}"
        #if source[0] == ?/
        #  logger.debug 'bah!'
        #  source
        #else
          source = digest_for(source.to_s)
          source = Pathname.new("/").join(dir, source).to_s
          source
        #end
      end

      def digest_available?(logical_path, ext)
        (manifest = Sprockets.manifest) && (manifest.assets[logical_path + "." + ext])
      end

      def digest_for(logical_path)
        if (manifest = Sprockets.manifest) && (digest = manifest.assets[logical_path])
          digest
        else
          logical_path
        end
      end

      def rewrite_extension(source, ext)
        if ext && File.extname(source) != "." + ext
          source + "." + ext
        else
          source
        end
      end

      def is_uri?(path)
        path =~ %r{^[-a-z]+://|^(?:cid|data):|^//}
      end

      def asset_for(source, ext)
        source = source.to_s
        return nil if is_uri?(source)
        source = rewrite_extension(source, ext)
        Sprockets.env[source]
      rescue Sprockets::FileOutsidePaths
        nil
      end

    end
  end
end

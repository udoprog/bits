require 'fileutils'

module Bits::Cache
  class FileCache
    attr_reader :cache

    def initialize(path)
      @path = path
      @cache = Hash.new
    end

    def bucket_for(bucket_name)
      bucket = cache[bucket_name]
      return bucket unless bucket.nil?
      cache[bucket_name] = load_bucket bucket_name
    end

    def []=(key, value)
      bucket = bucket_for(bucket_name key)
      bucket[key] = value
    end

    def [](key)
      bucket = bucket_for(bucket_name key)
      return nil if bucket.nil?
      bucket[key]
    end

    def set(content)
      content.each do |key, value|
        self[key] = value
      end
    end

    def save
      FileUtils.mkdir_p @path unless File.directory? @path

      @cache.each do |bucket_name, bucket|
        path = File.join @path, "#{bucket_name}.yml"

        File.open path, 'w' do |f|
          YAML.dump bucket, f
        end
      end
    end

    def bucket_name(string)
      string[0..1].each_byte.map { |b| sprintf("%02x",b) }.join
    end

    private

    def load_bucket(bucket_name)
      path = File.join @path, "#{bucket_name}.yml"

      return {} unless File.file? path

      File.open path do |f|
        return YAML.load_file f
      end
    end
  end

  def setup_cache(directory, cache_id)
    FileCache.new File.join(directory, cache_id.to_s)
  end
end

require 'graph_gist_tools'
require 'open-uri'

class GraphGistCandidate < GraphStarter::Asset
  has_one :out, :graphgist, type: :IS_VERSION, model_class: :GraphGist, unique: true

  property :title
  property :url, type: String
  property :raw_url, type: String

  property :asciidoc, type: String
  validates :asciidoc, presence: true
  property :raw_html, type: String
  validates :raw_html, presence: true

  property :query_cache, type: String
  validates :query_cache, presence: true

  property :status, type: String, default: 'candidate'
  enumerable_property :status, %w(live disabled candidate)

  has_one :in, :author, type: :WROTE, model_class: :Person

  property :cached, type: Boolean

  display_properties :title, :created_at

  hidden_json_properties :raw_html, :query_cache

  category_associations :author, :graphgist

  body_property :raw_html

  before_validation :place_current_url, if: :asciidoc_changed? || :url_changed?

  json_methods :html, :query_cache_html, :render_id, :persisted?

  def place_current_url
    if url.present?
      place_url(url)
      self.asciidoc = self.class.data_from_url(raw_url) if raw_url.present?
    end

    return if !asciidoc.present?

    place_asciidoc()
    place_query_cache()
  end

  def place_slug
    self.slug = self.class.unique_slug_from(safe_title + '-candidate')
  end

  def url_is_duplicate?
    self.class.url_is_duplicate?(url)
  end

  def self.url_is_duplicate?(url)
    if !url.present?
      return false
    else
      return !!find_by(url: url)
    end
  end

  SANITIZER = Rails::Html::WhiteListSanitizer.new
  VALID_HTML_TAGS = %w(a b body code col colgroup div em h1 h2 h3 h4 h5 h6 hr html i img li ol p pre span strong style table tbody td th thead tr ul)
  VALID_HTML_ATTRIBUTES = %w(id src href class style data-style graph-mode)

  def place_asciidoc
    document = asciidoctor_document

    place_attributes_from_document!(document)

    place_associations_from_document!(document)
  end

  def asciidoctor_document
    GraphGistTools.asciidoc_document(asciidoc)
  end

  def place_attributes_from_document!(document)
    self.raw_html = SANITIZER.sanitize(self.class.httpsize_img_srces(document.convert),
                                       tags: VALID_HTML_TAGS,
                                       attributes: VALID_HTML_ATTRIBUTES)

    self.raw_html += GraphGistTools.metadata_html(document)

    self.title ||= document.doctitle if document.doctitle.present?
  end

  def place_query_cache
    cypher_blocks = GraphGistTools.cypher_blocks(asciidoctor_document)
    queries = cypher_blocks.map(&:source)
    responses = []

    client = Neo4jConsole::Neo4jConsoleClient.new(asciidoctor_document.attributes['neo4j-version'])
    client.init
    queries.each do |query|
      response = client.cypher(query)
      responses.push JSON.parse(response.body)
    end
    self.query_cache = responses.to_json
  end

  HOSTS_TRANSFORMABLE_TO_HTTPS = %w(
    i\.imgur\.com
    imgur\.com
    .*\.photobucket\.com
    .*\.postimg\.org
    raw\.github\.com
    raw\.githubusercontent\.com
    .*\.giphy\.com
    .*\.blogspot\.com
    dl\.dropboxusercontent\.com
    www\.dropbox\.com
    docs\.google\.com
  )

  def self.httpsize_img_srces(html)
    doc = Nokogiri::HTML(html)

    img_srcs(doc).each do |src|
      begin
        uri = URI(src.value)
        next if uri.host.nil? || uri.scheme == 'https'

        uri.scheme = 'https' if host_is_httpsizable?(uri.host)

        src.value = uri.to_s
      rescue URI::InvalidURIError
        nil
      end
    end

    doc.xpath('//body').inner_html
  end

  def self.img_srcs(doc)
    doc.xpath('//img').map { |img| img.attribute('src') }.compact
  end

  def self.host_is_httpsizable?(host)
    HOSTS_TRANSFORMABLE_TO_HTTPS.any? { |test_host| host.match(/^#{test_host}$/) }
  end

  def place_associations_from_document!(document)
    if url = document.attributes['thumbnail']
      self.image = GraphStarter::Image.create(source: URI.parse(url), original_url: url)
    end

    twitter, author = document.attributes.values_at('twitter', 'author')
    self.author ||= Person.find_or_create({twitter_username: Person.standardized_twitter_username(twitter)}, name: author) if twitter
  end

  def place_url(new_url)
    self.url = new_url

    self.raw_url = GraphGistTools.raw_url_for(url) if url.present?
  end

  def html
    place_asciidoc if self.raw_html.empty?
    self.raw_html
  end

  def render_id
    id || Digest::SHA256.hexdigest("#{asciidoc}/#{created_at}")
  end

  def query_cache_html
    if not self.query_cache
      "<script></script>"
    else
      %Q(
        <script>
          var graphgist_cached_queries = #{self.query_cache};
        </script>
      )
    end
  end

  def self.create_from_graphgist(graphgist)
    self.create(
      graphgist: graphgist,
      status: graphgist.status,
      title: graphgist.title,
      url: graphgist.url,
      raw_url: graphgist.raw_url,
      asciidoc: graphgist.asciidoc,
      raw_html: graphgist.raw_html,
      cached: graphgist.cached,
      query_cache: graphgist.query_cache,
      author: graphgist.author,
      creators: graphgist.creators,
      created_at: graphgist.created_at,
      updated_at: graphgist.updated_at
    )
  end

  class << self
    def build_from_url(url)
      asciidoc_text = nil

      t = Benchmark.realtime { asciidoc_text = data_from_url(url) }
      Rails.logger.debug "Retrieved #{url} in #{t.round(1)}s"

      new(asciidoc: asciidoc_text, private: false)
    end

    def data_from_url(url)
      uri = URI(url)

      connection_from_uri(uri).get("#{uri.path}?#{uri.query}").body.force_encoding('UTF-8')
    rescue OpenURI::HTTPError
      nil
    end

    def connection_from_uri(uri)
      Faraday.new("#{uri.scheme}://#{uri.host}:#{uri.port}") do |b|
        b.use FaradayMiddleware::FollowRedirects
        b.adapter :net_http
      end.tap do |conn|
        conn.basic_auth(uri.user, uri.password) if uri.user.present? && uri.password.present?
      end
    end

    def from_graphgist_id(id)
      raw_url = GraphGistTools.raw_url_for_graphgist_id(id)

      return if !raw_url

      GraphGist.find_by(raw_url: raw_url) || GraphGist.new(url: raw_url, title: 'Preview')
    end
  end
end
module NginxConfigUtil
  def self.to_regex(path)
    segments = []
    while !path.empty?
      if path[0...2] == '**'
        segments << '.*'
        path = path[2..-1]
      elsif path[0...1] == '*'
        segments << '[^/]*'
        path = path[1..-1]
      else
        next_star = path.index("*") || path.length
        segments << Regexp.escape(path[0...next_star])
        path = path[next_star..-1]
      end
    end
    segments.join
  end

  def self.parse_routes(json)
    routes = json.map do |route, target|
      [to_regex(route), target]
    end

    Hash[routes]
  end

  def self.match_proxies(proxies, uri)
    return false unless proxies

    matched = proxies.select do |proxy|
      Regexp.compile("^#{proxy}") =~ uri
    end

    # return the longest matched proxy
    if matched.any?
      matched.max_by {|proxy| proxy.size }
    else
      false
    end
  end

  def self.match_redirects(redirects, uri)
    return false unless redirects

    redirects.each do |redirect|
      return redirect if redirect == uri
    end

    false
  end

  def self.match_pagination_error(redirects, uri)
    return false unless redirects

    redirects.find{ |redirect| uri.match /#{redirect}-\d+/ }&.gsub(/\//, '_')
  end

  def self.match_brands_redirects(redirects, uri)
    return false unless redirects

    redirects.find{|redirect| uri.end_with?(redirect)}
  end

  def self.match_dealers_error(all_city_redirects, uri)
    return false if all_city_redirects.empty?

    all_city_redirects.find{|c| uri.match(/#{c}\/.+/)}
  end

  def self.interpolate(string, vars)
    regex = /\${(\w*?)}/

    string.scan(regex).inject(string) do |acc, capture|
      var_name = capture.first
      value = vars[var_name] if vars
      acc.sub!("${#{var_name}}", value) if value

      acc
    end
  end
end

require 'json'

module LspClient
  @id = 0
  def self.fresh_id
    @id += 1
    @id
  end

  def self.send_request(pipe, method, params)
    content_part = {
      jsonrpc: '2.0',
      id: fresh_id,
      method: method,
      params: params
    }.to_json

    pipe.puts "Content-Length: #{content_part.length}\r\n\r\n#{content_part}"
  end

  def self.send_notification(pipe, method, params)
    content_part = {
      jsonrpc: '2.0',
      method: method,
      params: params
    }.to_json

    pipe.puts "Content-Length: #{content_part.length}\r\n\r\n#{content_part}"
  end

  def self.receive_response(pipe)
    raise unless /^Content-Length: (\d+)$/ === pipe.gets.strip
    pipe.gets
    JSON.parse(pipe.read($1.to_i))
  end
end

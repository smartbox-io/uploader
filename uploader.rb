require "json"
require "net/http"
require "net/http/post/multipart"

if ARGV.empty?
  puts "Usage: #{$0} file1 file2 file3..."
  Process.exit 1
end

def request(host: "localhost:3000", path:, method: :get, payload: nil, access_token: nil)
  uri = URI("http://#{host}/api/v1/#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  req = case method
    when :get
      Net::HTTP::Get.new(uri.path)
    when :post
      Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
    else
      raise "unknown method"
  end
  if access_token
    req["Authorization"] = "Bearer #{access_token}"
  end
  if !%i(get head).include?(method) && payload
    req.body = payload.to_json
  end
  JSON.parse(http.request(req).body, symbolize_names: true)
end

def login
  request path: "sessions", method: :post, payload: { username: "test", password: "test" }
end

def upload_file(access_token:)
  request path: "objects", method: :post, access_token: access_token
end

def upload_file_to_cell(access_token:, upload_token:, cell_ip:, filename:)
  uri = URI.parse("http://#{cell_ip}:6000/api/v1/objects/?upload_token=#{upload_token}")
  File.open(filename) do |file|
    req = Net::HTTP::Post::Multipart.new uri.request_uri,
                                         "object[payload]" => UploadIO.new(file, "application/data", filename)
    req["Authorization"] = "Bearer #{access_token}"
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request req
    end
    puts res.inspect
  end
end

access_token = login[:access_token]

uploads = Array.new
ARGV.count.times do
  uploads << upload_file(access_token: access_token)
end

uploads.each_with_index do |upload_info, i|
  upload_token = upload_info[:upload_token]
  cell_ip = upload_info[:cell][:ip_address]

  puts "Uploading file #{ARGV[i]}..."
  upload_file_to_cell access_token: access_token, upload_token: upload_token, cell_ip: cell_ip,
                      filename: ARGV[i]
end

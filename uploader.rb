require "json"
require "net/http"
require "net/http/post/multipart"

if ARGV.empty?
  puts "Usage: #{$PROGRAM_NAME} file1 file2 file3..."
  Process.exit 1
end

def request(host: "172.17.4.201", path:, method: :get, payload: nil, access_token: nil)
  response = perform_request host: host, path: path, method: method, payload: payload,
                             access_token: access_token
  puts response.inspect
  puts response.body
  JSON.parse response.body, symbolize_names: true
end

def perform_request(host:, path:, method:, payload:, access_token:)
  uri = URI("http://#{host}/api/v1/#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  req = build_request uri: uri, method: method
  req["Authorization"] = "Bearer #{access_token}" if access_token
  req.body = payload.to_json if !%i[head get delete].include?(method) && payload
  http.request req
end

def build_request(uri:, method:)
  case method
  when :get
    Net::HTTP::Get.new(uri.path)
  when :post
    Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
  else
    raise "unknown method"
  end
end

def login
  puts "Logging in..."
  request path: "sessions", method: :post, payload: { username: "test", password: "test" }
end

def upload_file(access_token:)
  request path: "objects", method: :post, access_token: access_token
end

def do_upload_file(uri:, access_token:, filename:)
  File.open(filename) do |file|
    req = Net::HTTP::Post::Multipart.new uri.request_uri,
                                         "object[payload]" => UploadIO.new(file, "application/data",
                                                                           filename)
    req["Authorization"] = "Bearer #{access_token}"
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request req
    end
  end
end

def upload_file_to_cell(access_token:, upload_token:, cell_ip:, filename:)
  uri = URI.parse("http://#{cell_ip}/api/v1/objects/?upload_token=#{upload_token}")
  puts uri.to_s
  response = do_upload_file uri: uri, access_token: access_token, filename: filename
  puts response.inspect
  puts response.body
end

access_token = login[:access_token]

uploads = []
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

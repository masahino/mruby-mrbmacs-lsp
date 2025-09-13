require 'json'

def create_response_message(id, result)
  {
    'jsonrpc' => '2.0',
    'result' => result,
    'id' => id
  }
end

def recv_request
  headers = {}
  while line = $stdin.gets
    break if line == "\r\n"

    k, v = line.chomp.split(':')
    headers[k] = v.to_i if k == 'Content-Length'
  end
  message = ''
  message = JSON.parse($stdin.read(headers['Content-Length'])) unless headers['Content-Length'].nil?
  [headers, message]
end

def send_response(id, result = {})
  message = create_response_message(id, result)
  json_message = message.to_json
  header = "Content-Length: #{json_message.length}\r\n\r\n"
  $stdout.print header
  $stdout.print json_message
  $stdout.flush
end

def send_specified_response(resp)
  id = resp['id']
  header = resp['params']['response']['header']
  message = if resp['params']['response']['message'].is_a?(Hash)
              create_response_message(id, resp['params']['response']['message']).to_json
            else
              resp['params']['response']['message'].to_s
            end
  $stdout.print header
  $stdout.print message
  $stdout.flush
end

loop do
  _readable, _writable = IO.select([$stdin])
  _headers, resp = recv_request
  if !resp['params'].nil? && !resp['params']['response'].nil?
    send_specified_response(resp)
    next
  end

  $stderr.puts "[REQUEST]#{resp['method']}"
  case resp['method']
  when 'shutdown'
    $stderr.puts '[shutdown]'
    exit
  else
    send_response(resp['id'])
  end
end

require 'json'

def create_response_message(id, result)
  {
    'jsonrpc' => '2.0',
    'result' => result,
    'id' => id,
  }
end

def recv_request
  headers = {}
  while line = STDIN.gets
    if line == "\r\n"
      break
    end
    k, v = line.chomp.split(":")
    if k == "Content-Length"
      headers[k] = v.to_i
    end
  end
  message = ""
  if headers["Content-Length"] != nil
    message = JSON.parse(STDIN.read(headers["Content-Length"]))
  end
  
  return headers, message
end

def send_response(id, result)
  message = create_response_message(id, result)
  json_message = message.to_json
  header = "Content-Length: " + json_message.length.to_s + "\r\n\r\n"
  STDOUT.print header
  STDOUT.print json_message
  STDOUT.flush
end

loop do
  headers, resp = recv_request
  case resp['method']
  when 'textDocument/definition'
    send_response(resp['id'], [
        {
          'uri' => 'file:///', 
          'range' => {
            'start' => {
              'line' => 0, 'character' => 0
            }
          }
        }
        ]
      )
  end
end
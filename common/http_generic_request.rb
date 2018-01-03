require 'net/http'
# Using SSL, current version of jruby just reads the file instead of passing it
# as a stream. This patch chunks the input manually if a SSLSocket is being
# used. 
# https://github.com/jruby/jruby/issues/4842
class Net::HTTPGenericRequest                                                                                                                                                                
  def send_request_with_body_stream(sock, ver, path, f)                                                                                                                                      
    unless content_length() or chunked?                                                                                                                                                      
      raise ArgumentError,                                                                                                                                                                   
          "Content-Length not given and Transfer-Encoding is not `chunked'"                                                                                                                  
    end                                                                                                                                                                                      
    supply_default_content_type                                                                                                                                                              
    write_header sock, ver, path                                                                                                                                                             
    wait_for_continue sock, ver if sock.continue_timeout                                                                                                                                     
    if chunked?                                                                                                                                                                              
      chunker = Chunker.new(sock)                                                                                                                                                            
      IO.copy_stream(f, chunker)                                                                                                                                                             
      chunker.finish                                                                                                                                                                         
    else                                                                                                                                                                                     
      # copy_stream can sendfile() to sock.io unless we use SSL.                                                                                                                             
      # If sock.io is an SSLSocket, copy_stream will hit SSL_write()                                                                                                                         
      if  sock.io.is_a? OpenSSL::SSL::SSLSocket                                                                                                                                              
        IO.copy_stream(f, sock.io, 16 * 1024 * 1024) until f.eof?                                                                                                                            
      else                                                                                                                                                                                   
        puts "sending stream... "
        IO.copy_stream(f, sock.io)                                                                                                                                                           
      end                                                                                                                                                                                    
    end                                                                                                                                                                                      
  end                                                                                                                                                                                        
end 

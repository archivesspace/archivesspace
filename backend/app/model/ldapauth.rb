require 'net/ldap'

class LDAPException < StandardError
end

class LDAPAuth

  include JSONModel


  def initialize(definition)
    required = [:hostname, :port, :base_dn, :username_attribute, :attribute_map]
    optional = [:bind_dn, :bind_password, :encryption, :extra_filter]

    required.each do |param|
      raise "LDAPAuth: Need a value for parameter :#{param}" if !definition[param]
      instance_variable_set("@#{param}", definition[param])
    end

    optional.each do |param|
      instance_variable_set("@#{param}", definition[param])
    end
  end


  def name
    "LDAPAuth - #{@hostname}:#{@port}"
  end


  def bind
    conn = Net::LDAP.new.tap do |conn|
      conn.host = @hostname
      conn.port = @port

      conn.auth(@bind_dn, @bind_password) if @bind_dn
      conn.encryption(@encryption) if @encryption
    end


    if conn.bind
      @connection = conn
    else
      msg = "Failed when binding to LDAP directory:\n\n#{self.inspect}\n\n"
      msg += "Error: #{conn.get_operation_result.message} (code = #{conn.get_operation_result.code})"
      raise LDAPException.new(msg)
    end
  end


  def bind_as_dn(user_dn, password)
    # Some LDAP servers treat a blank password as an anonymous bind.  Avoid
    # confusion by automatically rejecting auth attempts with a blank password.
    return nil if password.to_s.empty?

    @connection.auth(user_dn, password)
    @connection.bind
  end


  def find_user(username)
    filter = Net::LDAP::Filter.eq(@username_attribute, username)

    if @extra_filter
      filter = Net::LDAP::Filter.join(Net::LDAP::Filter.construct(@extra_filter), filter)
    end

    @connection.search(:base => @base_dn, :filter => filter).first
  end


  def authenticate(username, password)
    bind

    user = find_user(username.downcase)

    if user && bind_as_dn(user.dn, password)
      attributes = Hash[@attribute_map.map {|ldap_attribute, aspace_attribute|
                          [aspace_attribute, user[ldap_attribute].first]
                        }]

      JSONModel(:user).from_hash(attributes.merge(:username => username))
    end
  end


  def matching_usernames(query)
    bind

    filter = Net::LDAP::Filter.begins(@username_attribute, query)

    @connection.search(:base => @base_dn, :filter => filter).map {|entry|
      entry[@username_attribute].first
    }[0..AppConfig[:max_usernames_per_source].to_i]
  end

end

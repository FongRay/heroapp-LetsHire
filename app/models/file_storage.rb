require 'pg'
require 'mysql2'

class FileStorageImpl
  @@storages = %w(postgresql mongodb mysql)

  attr_accessor :buffer_size, :host, :port, :database

  def initialize(opts)
    if opts.has_key?(:storage)
      unless @@storages.include?(opts[:storage])
        #NOTE: Shall we define our own exception class?
        raise Exception.new("unknown storage")
      end
    else
      #NOTE: Shall we define our own exception class?
      raise Exception.new("unknown storage")
    end
    parse_args(opts)
    @buffer_size = 256
  end

  # NOTE: It's better to mark the following functions to be 'abstract'.
  def fini
  end

  def read(file, oid)
  end

  def write(file)
  end

  def clean(oid)
  end

  def file_length(oid)
  end

private
  def parse_args(opts)
    @host = opts[:host] if opts.has_key?(:host)
    @port = opts[:port] if opts.has_key?(:port)
    @user = opts[:user] if opts.has_key?(:user)
    @password = opts[:password] if opts.has_key?(:password)
    @database = opts[:database] if opts.has_key?(:database)

    #@host = "localhost" if @host.nil?
    #@port = "5432" if @port.nil?
  end
end

class MysqlStorage < FileStorageImpl
  def initialize(opts)
    opts[:storage] = 'mysql'
    super(opts)
    @conn = nil
    setup_client
  end

  def fini
    disconnect if conn_established?
  end

  def read(file, oid)
    if !file.methods.include?(:write) || oid < 0
      raise Exception.new("parameters invalid")
    end

    file.rewind

    results = client.query("select file from file_storage where id = #{oid}")
    results.each do |result|
      stream = result['file']
      file.write(hex_to_bin(stream))
    end
  end

  def write(file)
    file_hex_string = bin_to_hex(file.read)
    client.query("insert into file_storage(file) values('#{file_hex_string}')")
    oid = client.last_id
    oid
  end

  def clean(oid)
    client.query("delete from file_storage where id = #{oid}")
  end

  def file_length(oid)
    raise Exception.new('parameters invalid') if oid < 0

    length = 0

    results = client.query("select file from file_storage where id = #{oid}")
    results.each do |result|
      stream = result['file']
      length = stream.size
    end
    length
  end

private

  def bin_to_hex(s)
    s.unpack('H*').first
  end

  def hex_to_bin(s)
    s.scan(/../).map { |x| x.hex }.pack('c*')
  end

  def setup_client
    conf = {}
    conf[:host] = @host unless @host.nil?
    conf[:port] = @port unless @port.nil?
    conf[:username] = @user unless @user.nil?
    conf[:password] = @password unless @password.nil?
    conf[:database] = @database

    @conn ||= Mysql2::Client.new(conf)

    @conn.query('create table if not exists file_storage (id integer auto_increment, file longblob, primary key (id))')
  end

  def client
    @conn
  end

  def disconnect
    @conn.close
    @conn = nil
  end

  def conn_established?
    return true unless @conn.nil?
    false
  end

end

class PostgresqlStorage < FileStorageImpl
  def initialize(opts)
    opts[:storage] = 'postgresql'
    super(opts)
    @conn = nil
  end

  def fini
    disconnect if conn_established?
  end

  # Postgresql large object storage is based on pg_largeobject table, please
  # refer to 9.0 version official document about the pg_largeobject table,
  # http://www.postgresql.org/docs/9.0/static/catalog-pg-largeobject.html.
  #
  # Schema:
  # loid    oid, Identifier of the large object that includes this page
  # pageno int4, Page number of this page within its large object (counting from zero)
  # data  bytea, Actual data stored in the large object. This will never be more than LOBLKSIZE bytes and might be less.

  def read(file, oid)
    if !file.methods.include?(:write) || oid < 0
      #NOTE: Shall we define our own exception class?
      raise Exception.new("parameters invalid")
    end

    file.rewind
    connection.transaction do
      fd = connection.lo_open(oid, PGconn::INV_READ)
      total_size = connection.lo_lseek(fd, 0, PGconn::SEEK_END)
      connection.lo_lseek(fd, 0, PGconn::SEEK_SET)
      offset = 0
      while offset < total_size
        buffer = connection.lo_read(fd, @buffer_size)
        file.write(buffer)
        offset += buffer.length
      end
      connection.lo_close(fd)
    end
  end

  def write(file)
    if !file.methods.include?(:read)
      #NOTE: Shall we define our own exception class?
      raise Exception.new("parameters invalid")
    end

    oid = nil
    file.rewind
    connection.transaction do
      oid = connection.lo_creat(PGconn::INV_WRITE)
      fd = connection.lo_open(oid, PGconn::INV_WRITE)
      total_size = file.size
      offset = 0
      while offset < total_size
        buffer = file.read(@buffer_size)
        offset += buffer.length
        until buffer.empty?
          bytes = connection.lo_write(fd, buffer)
          buffer.slice!(0, bytes)
        end
      end
      connection.lo_close(fd)
    end
    return oid
  end

  def clean(oid)
    if oid < 0
      #NOTE: Shall we define our own exception class?
      raise Exception.new("parameters invalid")
    end

    connection.transaction do
      connection.lo_unlink(oid)
    end
  end

  def file_length(oid)
    if oid < 0
      #NOTE: Shall we define our own exception class?
      raise Exception.new("parameters invalid")
    end

    length = 0
    connection.transaction do
      fd = connection.lo_open(oid, PGconn::INV_READ)
      length = connection.lo_lseek(fd, 0, PGconn::SEEK_END)
      connection.lo_close(fd)
    end
    return length
  end

private
  # NOTE: Shall we need a connection pool? Currently let's make it simple.
  def connection
    conf = {}
    conf[:dbname] = @database
    conf[:host] = @host unless @host.nil?
    conf[:port] = @port unless @port.nil?
    conf[:user] = @user unless @user.nil?
    conf[:password] = @password unless @password.nil?
    @conn ||= PGconn.connect(conf)
    @conn
  end

  def disconnect
    @conn.finish
    @conn = nil
  end

  def conn_established?
    return true unless @conn.nil?
    false
  end

end

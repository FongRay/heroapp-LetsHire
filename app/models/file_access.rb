require 'pathname'
require 'file_storage'

class FileAccessBase

  attr_accessor :host, :port, :user, :password, :database

  def initialize(opts = nil)
    @storage = nil
    if opts.nil?
      parse_env
    else
      @host = opts[:host]
      @port = opts[:port]
      @user = opts[:username]
      @password = opts[:password]
      @database = opts[:database]
    end
  end

  def close
    storagelo.fini if storage_ready?
  end

private
  def parse_env
    dbconfig = Rails.configuration.database_configuration[Rails.env]
    @host     = dbconfig["host"]
    @port     = dbconfig["port"]
    @user     = dbconfig["username"]
    @password = dbconfig["password"]
    @database = dbconfig["database"]
    @adapter  = dbconfig["adapter"] || ''
  end

  def storagelo
    conf = {
      :host => @host,
      :port => @port,
      :user => @user,
      :password => @password,
      :database => @database
    }
    if @adapter.start_with? 'mysql'
      @storage ||= MysqlStorage.new(conf)
    else
      @storage ||= PostgresqlStorage.new(conf)
    end
    @storage
  end

  def storage_ready?
    return true unless @storage.nil?
    false
  end
end

class FileUploader < FileAccessBase
  def initialize(opts = nil)
    super(opts)
  end

  def upload(file)
    oid = nil
    if file.instance_of?(String) || file.instance_of?(Pathname)
      fp = File.open(file, 'rb')
      oid = storagelo.write(fp)
      fp.close
    else
      oid = storagelo.write(file)
    end
    return oid
  end
end

class FileDownloader < FileAccessBase
  def initialize(opts = nil)
    super(opts)
  end

  def download(file, oid)
    if file.instance_of?(String) || file.instance_of?(Pathname)
      fp = File.open(file, 'wb')
      storagelo.read(fp, oid)
      fp.close
    else
      storagelo.read(file, oid)
    end
  end
end

class FileCleaner < FileAccessBase
  def initialize(opts = nil)
    super(opts)
  end

  def clean(oid)
    storagelo.clean(oid)
  end
end

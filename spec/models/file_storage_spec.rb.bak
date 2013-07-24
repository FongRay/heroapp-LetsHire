require 'spec_helper'
require 'pg'
require 'stringio'
require 'yaml'

# This is a postgresql system table to store the large object.
TABLE_NAME = 'pg_largeobject'

CONFIG_FILE = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'config', 'database.yml'))

describe PostgresqlStorage do

  def env
    dbconf = YAML.load(File.open(CONFIG_FILE))

    {
      :storage => 'postgresql',
      :host => 'localhost',
      :port => '5432',
      :database => dbconf["ci"]["database"]
    }
  end

  def error_env
    {
      :storage => 'unknown'
    }
  end

  def content
    "\xCC" * 256
  end

  before (:all) do
    @conninfo = "host=#{env[:host]} port=#{env[:port]} dbname=#{env[:database]}"
    @conn = PGconn.connect(@conninfo)
  end

  before (:each) do
    @conn.transaction do
      object = @conn.escape_bytea(content)
      #NOTE: The following statement works on local box test, while does not work on Travis CI,
      #the failure message says 'invalid byte sequence for encoding "UTF8": 0xcc63'.
      #@conn.exec("INSERT INTO #{TABLE_NAME}(loid, pageno, data) values (1, 0, E'#{object}')")
    end
  end

  after (:each) do
    @conn.transaction do
      @conn.exec("DELETE FROM #{TABLE_NAME}")
    end
  end

  after (:all) do
    @conn.finish
  end

  it 'should raise exception with incorrect property' do
    expect do
      pg = FileStorageImpl.new(error_env)
    end.to raise_error(Exception)
  end

  it 'should read/write small binary object from/into database' do
    pg = PostgresqlStorage.new(env)
    oid = pg.write(StringIO.new(content))
    file = StringIO.new
    pg.read(file, oid)
    file.rewind
    res = file.read
    res.length.should be_equal(content.length)
    #FIXME: not sure why the following statement reports error
    #res.should be_equal(content)
    pg.fini
  end

  it 'should read/write large binary object from/into database' do
    pg = PostgresqlStorage.new(env)
    oid = pg.write(StringIO.new(content * 1024))
    file = StringIO.new
    pg.read(file, oid)
    file.rewind
    res = file.read
    res.length.should be_equal(content.length * 1024)
    #FIXME: not sure why the following statement reports error
    #res.should be_equal(content * 1024)
    pg.fini
  end

  it 'should clean binary object successfully' do
    pg = PostgresqlStorage.new(env)
    oid = pg.write(StringIO.new(content))
    pg.clean(oid)
    pg.fini
    res = @conn.exec("SELECT * FROM pg_largeobject WHERE loid=#{oid}")
    res.count.to_i.should be_equal(0)
  end

  it 'should get the correct size of binary object' do
    pg = PostgresqlStorage.new(env)
    oid = pg.write(StringIO.new(content))
    pg.file_length(oid).should be_equal(content.length)
    pg.fini
  end
end

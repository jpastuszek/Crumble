require 'model'

# requires rspec-2.6+
shared_context "with SQLite" do
  before do
    DataMapper::Logger.new($stdout, :debug)
    DataMapper::Model.raise_on_save_failure = true

    DataMapper.setup(:default, 'sqlite::memory:')

    DataMapper.finalize

    require  'dm-migrations'
    DataMapper.auto_migrate!
  end
end

describe NameServer do
  include_context "with SQLite"

  it "should store IP address" do
    n = NameServer.new(:ip => "192.168.7.1")
    n.save
    n = NameServer.get("192.168.7.1")
    n.ip.should == "192.168.7.1"
  end

  it "should not accept anything that is not valid IP address" do
    lambda {
      NameServer.new(:ip => "233.300.1.2")
    }.should raise_exception ArgumentError
  end

  it "should not accept name server of same IP" do
    lambda {
      NameServer.new(:ip => "192.168.7.1").save!
      NameServer.new(:ip => "192.168.7.1").save!
    }.should raise_exception DataObjects::IntegrityError
  end

  it "can belong to many systems" do
    n = NameServer.new(:ip => "192.168.7.1")
    s1 = System.new(:host_name => "test", :domain => "ns.com")
    s2 = System.new(:host_name => "test2", :domain => "ns.com")

    n.systems << s1
    n.systems << s2
    n.save

    n = NameServer.get("192.168.7.1")

    n.systems.length.should == 2
    n.systems.should include(s1, s2)
  end
end

describe Owner do
  include_context "with SQLite"

  it "has name, e_mail and comment" do
    Owner.new(:name => "Jakub P", :email => "jpa@bla.com", :comment => "hello").save
  end

  it "needs at least a name to be defined" do
    lambda {
      Owner.new.save!
    }.should raise_exception
    
    lambda {
      Owner.new(:name => "jakub").save!
    }.should_not raise_exception
  end

  it "should not accept two owners of the same name" do
    lambda {
      Owner.new(:name => "jakub").save!
      Owner.new(:name => "jakub").save!
    }.should raise_exception DataObjects::IntegrityError
  end

  it "should be possible to rename the owner after it is assigned to a system" do
      s = System.new(:host_name => "test", :domain => "xyz.com")
      o = Owner.new(:name => "jakub")
      s.owner = o
      s.save

      o.name = "zenon"
      o.save

      System.get("test", "xyz.com").owner.name.should == "zenon"
  end
end

describe System do
  include_context "with SQLite"

  it "should require host_name and domain properties" do
    lambda {
      System.new.save!
    }.should raise_exception

    lambda {
      System.new(:host_name => "test").save!
    }.should raise_exception
    
    lambda {
      System.new(:domain => "test").save!
    }.should raise_exception
    
    lambda {
      System.new(:host_name => "test", :domain => "xyz.com").save!
    }.should_not raise_exception
  end

  it "should have gateway propertie that accept IP address" do
    lambda {
      System.new(:host_name => "test", :domain => "xyz.com", :gateway => "192.168.1.1")
    }.should_not raise_exception

    lambda {
      System.new(:host_name => "test2", :domain => "xyz.com", :gateway => "192.300.1.1")
    }.should raise_exception
  end

  it "should not accept system of the same host name and domain" do
    lambda {
      System.new(:host_name => "test", :domain => "xyz.com").save!
      System.new(:host_name => "test", :domain => "xyz.com").save!
    }.should raise_exception DataObjects::IntegrityError
  end

  it "can have many name servers" do
      s = System.new(:host_name => "test", :domain => "xyz.com")
      n1 = NameServer.new(:ip => "192.168.1.1")
      n2 = NameServer.new(:ip => "192.168.1.2")
      s.name_servers << n1
      s.name_servers << n2
      s.save

      s = System.get("test", "xyz.com")
      s.name_servers.length.should == 2
      s.name_servers.should include(n1, n2)
  end

  it "may have an owner" do
      s = System.new(:host_name => "test", :domain => "xyz.com")
      o = Owner.new(:name => "me")
      s.owner = o
      s.save

      s = System.get("test", "xyz.com")
      s.owner.should == o
  end
end


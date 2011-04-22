require 'data_mapper'

DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true

DataMapper.setup(:default, 'sqlite::memory:')

DataMapper::Property::String.length(128)

class System
	include DataMapper::Resource

	property :host_name, String, :length => 32, :key => true
	property :domain, String,  :length => 64, :key => true

	property :gateway, IPAddress
	property :comment, Text

	belongs_to :owner, :required => false
	has n, :name_servers, :through => Resource
end

class Owner
	include DataMapper::Resource

	property :id, Serial
	property :name, String
	property :e_mail, String
	property :comment, Text

	has n, :systems
end

class NameServer
	include DataMapper::Resource

	property :ip, IPAddress, :key => true
	has n, :systems, :through => Resource
end

DataMapper.finalize

require  'dm-migrations'
DataMapper.auto_upgrade!

test01 = System.create(
	:host_name => "test01",
	:domain => "newbay.com"
)

jakub = Owner.create(
	:name => "Jakub Pastuszek"
)

jakub.systems << test01
jakub.save

p test01.owner

ns1 =NameServer.create(:ip => "192.168.2.19")
ns2 =NameServer.create(:ip => "192.168.2.38")

test01.name_servers << ns1
test01.name_servers << ns2
test01.save

test01.name_servers.each do |ns|
	p ns
end


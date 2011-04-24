require 'rubygems'
require 'data_mapper'

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

	property :name, String, :key => true
	property :email, String
	property :comment, Text

	has n, :systems
end

class NameServer
	include DataMapper::Resource

	property :ip, IPAddress, :key => true
	has n, :systems, :through => Resource
end


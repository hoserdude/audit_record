require 'rubygems'
require 'bundler'
require 'rails'
require 'active_record' 
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rails/test_help'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'audit'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.string :name
    t.boolean :is_admin, :default => false
  end
  create_table "audit_records", :force => true do |t|
    t.integer  "user_id"
    t.string   "action"
    t.text     "modifications"
    t.string   "remote_address"
    t.string   "auditable_type"
    t.integer  "auditable_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "audit_records", ["auditable_id", "auditable_type"], :name => "index_audit_records_on_auditable_id_and_auditable_type"
  add_index "audit_records", ["user_id"], :name => "index_audit_records_on_user_id"
end

class User < ActiveRecord::Base
  audit :methods => [:destroy], :attributes => [:is_admin]
end
class ActiveSupport::TestCase
  fixtures :all
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  def assert_difference(object, method = nil, difference = 1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference, object.send(method), "#{object}##{method}"
  end

  def assert_no_difference(object, method, &block)
    assert_difference object, method, 0, &block
  end
end
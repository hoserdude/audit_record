require 'helper'
class AuditTest < ActiveSupport::TestCase
    self.use_transactional_fixtures = false
    setup do
      AuditRecord.delete_all
      User.delete_all
    end

    should "create an audit record only when an auditable attribute is updated" do
      assert_no_difference(AuditRecord, :count) do
        @user = User.create(:name => "foo")
      end
      assert_difference(AuditRecord, :count) do
        @user.update_attribute(:is_admin, true)
      end
      @a = AuditRecord.last
      assert_equal "User", @a.auditable_type
      assert_equal( [false,true], @a.modifications["is_admin"])
    end
    should "create an audit record when observering a specific action" do
      assert_no_difference(AuditRecord, :count) do
        @user = User.create(:name => "foo")
      end
      assert_difference(AuditRecord, :count) do
        @user.destroy
      end
      @a = AuditRecord.last
      assert_equal(@user.class.to_s,@a.auditable_type)
      assert_equal(@user.id, @a.auditable_id)
      assert_equal("User.destroy was called",@a.action)
    end
    should "support :attributes => true to audit all attributes"
    should "support :attributes => %w(foo bar baz)"
    should "support :attributes => { :fields => %w(foo bar baz) }"
    should "support :attributes => { :fields => %w(foo bar baz) :if => Proc.new {|a| a == b} }"
    should "support :attributes => { :fields => %w(foo bar baz) :unless => Proc.new {|a| a != b} }"
    should "support :methods => true"
    should "support :methods => %w(save destroy update create)"
    should "support :methods => { :in => %w(foo bar baz) }"
    should "support :methods => { :in => %w(foo bar baz), :if => Proc.new {|a| a == b} }"
    should "support :methods => { :in => %w(foo bar baz), :unless => Proc.new {|a| a == b} }"
    should "allow the model to be reverted back to values in the model"
end

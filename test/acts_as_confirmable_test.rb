require 'test/unit'

require 'rubygems'
require 'active_record'

$:.unshift File.dirname(__FILE__) + '/../lib'
require File.dirname(__FILE__) + '/../init'

class Test::Unit::TestCase
  def assert_queries(num = 1)
    $query_count = 0
    yield
  ensure
    assert_equal num, $query_count, "#{$query_count} instead of #{num} queries were executed."
  end

  def assert_no_queries(&block)
    assert_queries(0, &block)
  end
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

# AR keeps printing annoying schema statements
$stdout = StringIO.new

def setup_db
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define(:version => 1) do
    create_table :mixins do |t|
      t.column :recorded_confirmed_by, :integer
      t.column :recorded_confirmed_at, :date_time
      t.column :produced_confirmed_by, :integer
      t.column :produced_confirmed_at, :date_time
      t.column :edited_confirmed_by, :integer
      t.column :edited_confirmed_at, :date_time
    end
    
    create_table :users do |t|
      t.column :name, :string
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Mixin < ActiveRecord::Base
end

class User < Mixin
  cattr_accessor :current_user
end

class SingleConfirmableMixin < Mixin 
  acts_as_confirmable :recorded
end

class MultipleConfirmableMixin < Mixin 
  acts_as_confirmable :recorded, :produced, :edited
end


class ConfirmableTest < Test::Unit::TestCase
  
  def setup
    setup_db
    @mixin = SingleConfirmableMixin.new
    @user = User.create!
    User.current_user = @user
  end

  def teardown
    teardown_db
  end
  
  def test_accessing_as_boolean
    @mixin.recorded_confirmed_at = Date.today
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded, true)
  end

  def test_accessing_as_boolean_with_no_confirmed_by
    @mixin.recorded_confirmed_at = Date.today
    @mixin.recorded_confirmed_by = nil
    assert_equal(@mixin.recorded, false)
  end

  def test_accessing_as_boolean_with_no_confirmed_at
    @mixin.recorded_confirmed_at = nil
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded, false)
  end
  
  def test_assigning_as_boolean
    @mixin.recorded = true
    assert_equal(@mixin.recorded, true)
    assert_equal(@mixin.recorded_confirmed_at.to_s, Time.now.to_s)
    assert_equal(@mixin.recorded_confirmed_by, 1)
  end

  def test_assigning_as_string
    @mixin.recorded = "2008-02-21"
    assert_equal(@mixin.recorded, true)
    assert_equal(@mixin.recorded_confirmed_at, Date.new(2008,2,21).to_time)
    assert_equal(@mixin.recorded_confirmed_by, 1)
  end
  
  def test_no_queries
    assert_no_queries do
      @mixin.recorded = true
      assert_equal(@mixin.recorded?, true)
    end
  end

  def test_reassigning_as_boolean
    @mixin.recorded_confirmed_at = Date.today - 3.days
    @mixin.recorded_confirmed_by = 2
    @mixin.recorded = true
    assert_equal(@mixin.recorded, true)
    assert_equal(@mixin.recorded_confirmed_at, Date.today - 3.days)
    assert_equal(@mixin.recorded_confirmed_by, 2)

    @mixin.recorded = false
    @mixin.recorded = true
    assert_equal(@mixin.recorded, true)
    assert_equal(@mixin.recorded_confirmed_at.to_s, Time.now.to_s)
    assert_equal(@mixin.recorded_confirmed_by, 1)
  end
  
  def test_confirmed_with_date_and_by
    @mixin.recorded_confirmed_at = Date.today
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded?, true)
  end

  def test_confirmed_field_for_check_box
    @mixin.recorded_confirmed_at = Date.today
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded, true)
  end

  def test_no_date_no_confirmation
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded?, false)
  end

  def test_no_confirmer_no_confirmation
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded?, false)
  end
  
  def test_load_confirmer
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded_confirmer, @user)
  end
  
  def test_assign_confirmer
    @another_user = User.create!
    @mixin.recorded_confirmer = @another_user
    assert_equal(@mixin.recorded_confirmer, @another_user)
  end
  
  def test_simple_date
    @mixin.recorded_confirmed_at = Date.today
    assert_equal(@mixin.recorded_confirmed_at, Date.today)
  end
  
  def test_no_date
    assert_equal(@mixin.recorded?, false)
  end
end

class MultipleConfirmableTest < Test::Unit::TestCase
  
  def setup
    setup_db
    @mixin = MultipleConfirmableMixin.new
    @user = User.create!
  end

  def teardown
    teardown_db
  end
  
  def test_confirmed_with_date_and_by
    @mixin.recorded_confirmed_at = Date.today
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded?, true)
  end

  def test_no_date_no_confirmation
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded?, false)
  end

  def test_no_confirmer_no_confirmation
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded?, false)
  end
  
  def test_load_confirmer
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded_confirmer, @user)
  end
  
  def test_assign_confirmer
    @another_user = User.create!
    @mixin.recorded_confirmer = @another_user
    assert_equal(@mixin.recorded_confirmer, @another_user)
  end
  
  def test_simple_date
    @mixin.recorded_confirmed_at = Date.today
    assert_equal(@mixin.recorded_confirmed_at, @mixin.recorded_at)
  end
  
  def test_no_date
    assert_equal(@mixin.recorded?, false)
  end
  
end
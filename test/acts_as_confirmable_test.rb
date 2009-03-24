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
  
  def test_checkbox_assigning
    @mixin.recorded = "1"
    assert_equal(@mixin.recorded, true)
    assert_in_delta(@mixin.recorded_confirmed_at, DateTime.now, 1.seconds)
    assert_equal(@mixin.recorded_confirmed_by, 1)

    @mixin.recorded = "0"
    assert_equal(@mixin.recorded, false)
    assert_equal(@mixin.recorded_confirmed_at, nil)
    assert_equal(@mixin.recorded_confirmed_by, nil)
  end

  def test_boolean_assigning
    @mixin.recorded = true
    assert_equal(@mixin.recorded, true)
    assert_in_delta(@mixin.recorded_confirmed_at, DateTime.now, 1.seconds)
    assert_equal(@mixin.recorded_confirmed_by, 1)

    @mixin.recorded = false
    assert_equal(@mixin.recorded, false)
    assert_equal(@mixin.recorded_confirmed_at, nil)
    assert_equal(@mixin.recorded_confirmed_by, nil)
  end

  def test_accessing_as_boolean
    @mixin.recorded_confirmed_at = DateTime.now
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded?, true)
    assert_equal(@mixin.recorded, true)
  end

  def test_direct_assigning_to_confirmed_at
    @mixin.recorded_confirmed_at = DateTime.now
    @mixin.recorded_confirmed_by = nil
    assert_equal(@mixin.recorded?, false)
    assert_equal(@mixin.recorded, false)
  end

  def test_direct_assigning_to_confirmed_by
    @mixin.recorded_confirmed_at = nil
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded?, false)
    assert_equal(@mixin.recorded, false)
  end
  
  def test_direct_assigning_to_confirmer
    @another_user = User.create!
    @mixin.recorded_confirmer = @another_user
    assert_equal(@mixin.recorded, false)
    assert_equal(@mixin.recorded_confirmed_by, @another_user.id)
    assert_equal(@mixin.recorded_confirmer, @another_user)
  end
  
  def test_no_clobbering
    @mixin.recorded_confirmed_at = DateTime.now - 3.days
    @mixin.recorded_confirmed_by = 2
    assert_equal(@mixin.recorded, true)
    
    @mixin.recorded = true
    assert_equal(@mixin.recorded, true)
    assert_equal(@mixin.recorded_confirmed_at, DateTime.now - 3.days)
    assert_equal(@mixin.recorded_confirmed_by, 2)
  end
  
  def test_fields_cleaned
    @mixin.recorded_confirmed_at = DateTime.now - 3.days
    @mixin.recorded_confirmed_by = 2
    assert_equal(@mixin.recorded, true)

    @mixin.recorded = false
    assert_equal(@mixin.recorded, false)
    assert_equal(@mixin.recorded_confirmed_at, nil)
    assert_equal(@mixin.recorded_confirmed_by, nil)
  end
  
  def test_confirmed_with_datetime_and_by
    @mixin.recorded_confirmed_at = DateTime.now
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded?, true)
  end

  def test_confirmed_with_date_and_by
    @mixin.recorded_confirmed_at = Date.today
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded?, true)
  end

  def test_load_confirmer
    @mixin.recorded_confirmed_by = 1
    assert_equal(@mixin.recorded_confirmer, @user)
  end
  
  def test_accessing_date
    @mixin.recorded_confirmed_at = DateTime.now
    assert_equal(@mixin.recorded_confirmed_at, @mixin.recorded_at)
  end
  
  def test_performs_no_queries
    assert_no_queries do
      @mixin.recorded = true
      assert_equal(@mixin.recorded?, true)
    end
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
  
  def test_checkbox_assigning
    @mixin.recorded = "1"
    @mixin.produced = "1"
    assert_equal(@mixin.recorded, true)
    assert_in_delta(@mixin.recorded_confirmed_at, DateTime.now, 1.seconds)
    assert_equal(@mixin.recorded_confirmed_by, 1)

    assert_equal(@mixin.produced, true)
    assert_equal(@mixin.edited, false)
  end
end
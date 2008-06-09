require 'test/unit'

require 'rubygems'
require 'active_record'

$:.unshift File.dirname(__FILE__) + '/../lib'
require File.dirname(__FILE__) + '/../init'

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

class SingleConfirmableMixin < Mixin 
  acts_as_confirmable :recorded
end

class MultipleConfirmableMixin < Mixin 
  acts_as_confirmable :recorded, :produced, :edited
end

class User < Mixin
end

class ConfirmableTest < Test::Unit::TestCase
  
  def setup
    setup_db
    @mixin = SingleConfirmableMixin.new
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
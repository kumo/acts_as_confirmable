require 'acts_as_confirmable'
ActiveRecord::Base.send :include, Kumo::Acts::Confirmable
module Kumo
  module Acts
    module Confirmable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_confirmable(*attr_names)
          attr_names.each do |attr_name|
          class_eval <<-EOV
            include Kumo::Acts::Confirmable::InstanceMethods

              define_method("#{attr_name.to_s}?") do
                self.send("#{attr_name}_confirmed_at") != nil and
                  self.send("#{attr_name}_confirmed_by") != nil
              end

              # used to assign check boxes
              define_method("#{attr_name.to_s}=") do |value|
                if value == "0" or value == false
                  self.send("#{attr_name}_confirmed_by=", nil)
                  self.send("#{attr_name}_confirmed_at=", nil)
                else
                  if self.send("#{attr_name.to_s}?") == false
                    self.send("#{attr_name}_confirmed_at=", Date.today)
                    self.send("#{attr_name}_confirmed_by=", (User.current_user.id rescue 1))
                  end
                end
              end

              define_method("#{attr_name.to_s}_at") do
                self.send("#{attr_name}_confirmed_at")
              end

              define_method("#{attr_name.to_s}_confirmer") do
                confirmer_id = self.send("#{attr_name}_confirmed_by")

                confirmer_id.nil? ? nil : User.find_by_id(confirmer_id)             
              end

              define_method("#{attr_name}_confirmer=") do |who|
                if who.is_a? User
                  who = who.id
                elsif not who.is_a? Integer
                  who = nil
                end

                self.send("update_attribute", "#{attr_name}_confirmed_by", who)
              end

              # used for check boxes
              alias_method "#{attr_name.to_s}", "#{attr_name.to_s}?"
            EOV
          end     
        end
      end
         
      module InstanceMethods
      end
    end
  end
end
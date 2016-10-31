module Sapience
  module Extensions
    module ActiveRecord
      module ModelMetrics
        def self.included(base) # rubocop:disable AbcSize
          base.extend(ClassMethods)
          base.class_eval do
            const_set(:SAPIENCE_MODEL_CREATE_METRICS_KEY,  "model.#{tableized_name}.create")
            const_set(:SAPIENCE_MODEL_UPDATE_METRICS_KEY,  "model.#{tableized_name}.update")
            const_set(:SAPIENCE_MODEL_DESTROY_METRICS_KEY, "model.#{tableized_name}.destroy")

            before_create do
              Sapience.metrics.increment(self.class.const_get(:SAPIENCE_MODEL_CREATE_METRICS_KEY))
            end if respond_to?(:before_create)

            before_update do
              Sapience.metrics.increment(self.class.const_get(:SAPIENCE_MODEL_UPDATE_METRICS_KEY))
            end if respond_to?(:before_update)

            before_destroy do
              Sapience.metrics.increment(self.class.const_get(:SAPIENCE_MODEL_DESTROY_METRICS_KEY))
            end if respond_to?(:before_destroy)
          end
        end

        module ClassMethods
          def tableized_name
            @tableized_name ||= name.tableize.singularize.gsub("/", ".")
          end
        end

        def tableized_name
          self.class.tableized_name
        end
      end
    end
  end
end

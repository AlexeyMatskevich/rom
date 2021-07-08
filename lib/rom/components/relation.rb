# frozen_string_literal: true

require_relative "core"

module ROM
  module Components
    # @api public
    class Relation < Core
      id :relation

      # @!attribute [r] constant
      #   @return [.new] Relation instance builder (typically a class)
      option :constant, type: Types.Interface(:new)

      # @!attribute [r] gateway
      #   @return [Symbol] The default gateway id
      option :gateway, type: Types::Strict::Symbol, inferrable: true

      # @!attribute [r] dataset
      #   @return [Symbol] The default dataset id
      option :dataset, type: Types::Strict::Symbol, inferrable: true

      # Registry namespace
      #
      # @return [String]
      #
      # @api public
      def namespace
        "relations"
      end

      # @return [ROM::Relation]
      #
      # @api public
      memoize def build
        constant.use(:registry_reader, relations: components.relations.map(&:id))

        trigger("relations.class.ready", relation: constant, adapter: adapter)

        apply_plugins

        payload = {
          schema: schema,
          adapter: adapter,
          gateway: gateway,
          relation: constant,
          registry: relations
        }

        trigger("relations.schema.set", payload)

        relation = constant.new(**relation_options)

        trigger("relations.object.registered", registry: relations, relation: relation)

        relation
      end

      private

      # @api private
      def relation_options
        {schema: schema,
         inflector: inflector,
         datasets: configuration.datasets,
         schemas: configuration.schemas,
         associations: associations,
         mappers: configuration.mappers.new(id, adapter: adapter),
         commands: configuration.commands.new(id, adapter: adapter),
         __registry__: relations, # TODO: rename
         **plugin_options} # TODO: rename
      end

      # @api private
      def schema
        configuration.schemas[dataset]
      end

      # @api private
      def associations
        configuration.associations.new(id, provider: constant, items: schema.associations)
      end
    end
  end
end

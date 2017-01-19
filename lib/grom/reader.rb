require 'pry'

module Grom
  class Reader
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def create_hashes
      # Reset all our hashed just in-case
      @statements_by_subject  = {}
      @subjects_by_type       = {}
      @connections_by_subject = {}
      @objects_by_subject     = {}

      RDF::NTriples::Reader.new(@data) do |reader|
        reader.each_statement do |statement|
          subject = statement.subject.to_s
          @statements_by_subject[subject] ||= []
          @statements_by_subject[subject] << statement

          predicate = statement.predicate.to_s

          # is this statement a type definition?
          if predicate == RDF.type.to_s
            @subjects_by_type[Grom::Reader.get_id(statement.object)] ||= []
            @subjects_by_type[Grom::Reader.get_id(statement.object)] << subject
          end

          # TODO: Rewrite to check for object as a URI
          if ((statement.object =~ URI::regexp) == 0) && predicate != RDF.type.to_s
            @connections_by_subject[subject] ||= []
            @connections_by_subject[subject] << statement.object.to_s
          end
        end
      end

      self
    end

    def create_objects_by_subject
      objects = []
      @subjects_by_type.each do |type, subjects|
        subjects.each do |subject|
          begin
            object = Grom::Node.new(@statements_by_subject[subject])
            @objects_by_subject[subject] = object
            objects << object
          rescue
          end
        end
      end

      objects
    end

    def self.get_id(uri)
      return nil if uri.to_s['/'].nil?

      uri == RDF.type.to_s ? 'type' : uri.to_s.split('/').last
    end
  end
end


=begin
def self.process_ttl_data(data: data)



    @connections_by_subject.each do |subject, connections|

      current_node = objects_by_subject[subject]
      connections.each do |connection_subject|
        begin
          connection_node = objects_by_subject[connection_subject]
          connector_name = create_plural_property_name(current_node.class.name)
          connector_name_symbol = "@#{connector_name}".to_sym

          connected_object_array = connection_node.instance_variable_get(connector_name_symbol)
          connected_object_array = [] if connected_object_array.nil?
          connected_object_array << current_node
          connection_node.instance_variable_set(connector_name_symbol, connected_object_array)

          #this is not dry and quite smelly but just to prove that we can have reciprocal relationships
          rec_connector_name = create_plural_property_name(connection_node.class.name)
          rec_connector_name_symbol = "@#{rec_connector_name}".to_sym

          rec_connected_object_array = current_node.instance_variable_get(rec_connector_name_symbol)
          rec_connected_object_array = [] if rec_connected_object_array.nil?
          rec_connected_object_array << connection_node
          current_node.instance_variable_set(rec_connector_name_symbol, rec_connected_object_array)
        rescue
        end
      end
    end

    objects
  end
=end
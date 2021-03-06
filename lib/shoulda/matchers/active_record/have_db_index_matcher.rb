module Shoulda # :nodoc:
  module Matchers
    module ActiveRecord # :nodoc:

      # Ensures that there are DB indices on the given columns or tuples of
      # columns.
      #
      # Options:
      # * <tt>unique</tt> - whether or not the index has a unique
      #   constraint. Use <tt>true</tt> to explicitly test for a unique
      #   constraint.  Use <tt>false</tt> to explicitly test for a non-unique
      #   constraint.
      #
      # Examples:
      #
      #   it { should have_db_index(:age) }
      #   it { should have_db_index([:commentable_type, :commentable_id]) }
      #   it { should have_db_index(:ssn).unique(true) }
      #
      def have_db_index(columns)
        HaveDbIndexMatcher.new(columns)
      end

      class HaveDbIndexMatcher # :nodoc:
        def initialize(columns)
          @columns = normalize_columns_to_array(columns)
          @options = {}
        end

        def unique(unique)
          @options[:unique] = unique
          self
        end

        def matches?(subject)
          @subject = subject
          index_exists? && correct_unique?
        end

        def failure_message
          "Expected #{expectation} (#{@missing})"
        end

        def negative_failure_message
          "Did not expect #{expectation}"
        end

        def description
          if @options.key?(:unique)
            "have a #{index_type} index on columns #{@columns.join(' and ')}"
          else
            "have an index on columns #{@columns.join(' and ')}"
          end
        end

        protected

        def index_exists?
          ! matched_index.nil?
        end

        def correct_unique?
          return true unless @options.key?(:unique)

          if matched_index.unique == @options[:unique]
            true
          else
            @missing = "#{table_name} has an index named #{matched_index.name} " <<
                       "of unique #{matched_index.unique}, not #{@options[:unique]}."
            false
          end
        end

        def matched_index
          indexes.detect { |each| each.columns == @columns }
        end

        def model_class
          @subject.class
        end

        def table_name
          model_class.table_name
        end

        def indexes
          ::ActiveRecord::Base.connection.indexes(table_name)
        end

        def expectation
          "#{model_class.name} to #{description}"
        end

        def index_type
          if @options[:unique]
            'unique'
          else
            'non-unique'
          end
        end

        def normalize_columns_to_array(columns)
          Array.wrap(columns).map(&:to_s)
        end
      end
    end
  end
end

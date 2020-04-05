require 'parlour'
require 'open3'
require 'fast'

module SorbetDuck
  module DuckDefinitionFinder
    def self.project_files
      # Mostly pinched from Parlour
      stdin, stdout, stderr, wait_thr = T.unsafe(Open3).popen3(
        'bundle exec srb tc -p file-table-json',
      )

      file_table_hash = JSON.parse(T.must(stdout.read))
      file_table_entries = file_table_hash['files']

      paths = []
      file_table_entries.each do |file_table_entry|
        next if file_table_entry['sigil'] == 'Ignore' ||
          file_table_entry['strict'] == 'Ignore'

        path = file_table_entry['path']
        next if path.start_with?('./sorbet/rbi/hidden-definitions/')

        # There are some entries which are URLs to stdlib
        next unless File.exist?(path)

        paths << path
      end

      paths
    end

    def self.find_definitions_in_source(source)
      # Search for Duck interface definitions in the form:
      #   duck(:InterfaceName, :method_name) { ... }
      results = Fast.search(
        '(block (send nil :duck (sym $_) (sym $_)) (args) $_)',
        Fast.ast(source)
      )

      # Fast returns a flat array of results: the complete matching AST, and our
      # three matches, for each result. We don't need the complete AST, so let's
      # discard that and give the other things some depth
      raw_definitions = results.each_slice(4).map do |_, int_name, meth_name, meth_type_ast|
        [int_name, meth_name, meth_type_ast]
      end
      
      # Instantiate Duck interface objects from these
      interfaces = raw_definitions.map do |int_name, meth_name, meth_type_ast|
        s = ->(type, *children) { Parser::AST::Node.new(type, children) }
        
        # Wrap the AST in a "sig { ... }"
        wrapped_ast = s.(:block,
          s.(:send, nil, :sig),
          s.(:args),
          meth_type_ast
        )

        # Parse the signature with Parlour
        parser = Parlour::TypeParser.new(wrapped_ast)
        sig = parser.parse_sig_into_sig(Parlour::TypeParser::NodePath.new([]))

        # Build an abstract method from this signature
        method = Parlour::RbiGenerator::Method.new(
          Parlour::DetachedRbiGenerator.new,
          meth_name.to_s,
          [], # TODO: params are currently unsupported!
          sig.return_type,
          abstract: true,
          override: sig.override,
          overridable: sig.overridable,
          final: sig.final,
          type_parameters: sig.type_parameters,
        )

        # Create the DuckInterface object
        DuckInterface.new(int_name.to_s, method)
      end
    end

    def self.find_all_definitions
      project_files.flat_map do |file|
        find_definitions_in_source(File.read(file))
      end
    end
  end
end

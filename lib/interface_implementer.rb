# typed: ignore

require_relative 'lsp_client'

module InterfaceImplementer
  def self.run_lsp_diagnostics
    # TODO: hangs if there aren't any errors
    pipe = IO.popen(['srb', 'tc', '--lsp'], 'r+')
    LspClient.send_request(pipe, 'initialize', {
      processId: nil,
      rootUri: nil,
      capabilities: {
        textDocument: {
          publishDiagnostics: {
            relatedInformation: true
          },
        }
      },
    })
    LspClient.receive_response(pipe)
    LspClient.send_notification(pipe, 'initialized', {})
    result = LspClient.receive_response(pipe)
    pipe.close
    result
  end
  
  def self.implement(root_rbi_object, duck_interfaces)
    diagnostics = run_lsp_diagnostics['params']['diagnostics']

    # Find all cases where the Duck interface exists but may not have been
    # implemented for a type
    unimplemented_duck_diagnostics = diagnostics.select do |x|
      x['code'] == 7002 && /Expected `([^`]+::)*Duck::[A-Za-z0-9_]+`/ === x['message']
    end

    # Pick out the Duck interface names and target type names
    duck_interfaces_and_targets = unimplemented_duck_diagnostics.map do |x|
      raise 'malformed message' unless /^Expected `(?:[^`]+::)*Duck::(.+)` but found `(\[?[A-Za-z0-9_:]+)/ === x['message']
      interface, target = $1, $2

      # Special case: the T::Array-like enumerable objects are actually modules
      # and implementing the interfaces on them won't work. Implement them on
      # the real classes instead
      if ['T::Array', 'T::Hash', 'T::Set', 'T::Enumerable', 'T::Enumerator', 'T::Range'].include?(target)
        target.gsub!('T::', '')
      end

      # Special case: a literal array may have a type shown as "[...]"
      if target.start_with?('[')
        target = 'Array'
      end

      [interface, target]
    end

    # Implement the interface for all of these classes
    duck_interfaces_and_targets.each do |interface_name, target|
      interface = duck_interfaces.find { |x| x.interface_name == interface_name }
      raise "interface #{interface_name} does not exist" unless interface
      interface.implement_for_class(root_rbi_object, target)
    end

    nil
  end
end

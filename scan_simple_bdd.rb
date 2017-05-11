class SimpleBddScanner
  def scan_files
    output_string = ''
    scan_output.each do |file_path, method_names|
      output_string += "#{file_path}:\n"
      method_names.each do |method_name|
        output_string += "\t#{method_name}\n"
      end
      output_string += "\n"
    end

    output_string
  end

  private

  def scan_output
    file_paths = Dir.glob('spec/features/**/*_spec.rb')
    scan_output = {}

    file_paths.each do |file_path|
      scan_output[file_path] = scan_file(file_path)
    end

    scan_output.reject{ |_, method_names| method_names.empty? }
  end

  def scan_file(file_path)
    spec_file = File.open(file_path)

    method_names = spec_file.map do |line|
      line_match = /def ([a-zA-Z0-9\-\_]*)/.match(line)
      line_match[1] if line_match
    end.compact

    used_step_names = used_step_names(spec_file)
    direct_method_calls = direct_method_calls(spec_file, method_names)

    method_names - (used_step_names + direct_method_calls).uniq
  end

  def used_step_names(file)
    file.rewind
    step_definitions = file.map do |line|
      line_match_single_quote = /(Given|When|Then|And|But)[ ]*'(.*)'/.match(line)
      line_match_double_quote = /(Given|When|Then|And|But)[ ]*"(.*)"/.match(line)

      line_match = line_match_single_quote || line_match_double_quote
      line_match[2] if line_match
    end.compact

    step_definitions.map do |step_definition|
      step_definition.downcase.gsub(/[^a-zA-Z0-9\ \-\_]/, '').gsub(/ |-/, '_')
    end.uniq
  end

  def direct_method_calls(file, method_names)
    method_names.select do |method_name|
      file.rewind
      file.detect do |line|
        match = /(def )?the_dates_are_correct/.match(line)
        match && !match[1]
      end
    end
  end
end

scanner = SimpleBddScanner.new
puts scanner.scan_files

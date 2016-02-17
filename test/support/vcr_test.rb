module VcrTest
  def vcr_test(name, group = nil, vcr_options ={}, &block)
    # cribbed from Rails and modified for VCR
    # https://github.com/rails/rails/blob/b451de0d6de4df6bc66b274cec73b919f823d5ae/activesupport/lib/active_support/testing/declarative.rb#L25

    if group.nil?
      group = self.name.underscore
    end

    test_name_safe = name.gsub(/\s+/,'_')

    test_method_name = "test_#{test_name_safe}".to_sym

    raise "#{test_method_name} is already defined in #{self}" if methods.include?(test_method_name)

    cassette_name = vcr_options.delete(:cassette)
    unless cassette_name
      # calculate default cassette name from test name
      cassette_name = test_name_safe
    end

    # put in group subdir if group
    cassette_name = "#{group}/#{cassette_name}" if group

    # default tag with groupname, can be over-ridden.
    vcr_options = {:tag => group}.merge(vcr_options) if group

    if block_given?
      define_method(test_method_name) do
        VCR.use_cassette(cassette_name , vcr_options) do
          instance_eval &block
        end
      end
    else
      define_method(test_method_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end
end
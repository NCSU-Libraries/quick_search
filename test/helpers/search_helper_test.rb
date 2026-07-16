require 'test_helper'

class SearchHelperTest < ActionView::TestCase
	test 'prefers canonical name for misspelled full name' do
		with_stubbed_names(['John Smith']) do
			assert_equal ['John Smith'], spell_check('jon smth')
		end
	end

	test 'prefers canonical name token over regular-word hunspell suggestion' do
		with_stubbed_names(['John Smith']) do
			SPELL_CHECKER.stub(:check?, false) do
				SPELL_CHECKER.stub(:suggest, ['join']) do
					assert_equal ['John'], spell_check('jon')
				end
			end
		end
	end

	test 'still uses hunspell for regular misspellings when no name matches' do
		with_stubbed_names([]) do
			SPELL_CHECKER.stub(:check?, false) do
				SPELL_CHECKER.stub(:suggest, ['spelling']) do
					assert_equal ['spelling'], spell_check('speling')
				end
			end
		end
	end

	test 'combines webnodes names with configured names' do
		with_stubbed_name_sources(webnodes: ['John Smith'], configured: ['Jane Doe']) do
			assert_equal ['John Smith', 'Jane Doe'], names_dictionary
		end
	end

	test 'uses author names from search results as a fallback corpus' do
		with_stubbed_name_sources(webnodes: [], configured: []) do
			searcher = Struct.new(:results).new([
				OpenStruct.new(author: 'Olson, Jonathan R; Welsh, Janet A')
			])

			assert_equal ['Jonathan'], spell_check_from_searchers('Jonathn', [searcher])
		end
	end

	test 'filters out exact typo token from fallback candidates' do
		with_stubbed_name_sources(webnodes: [], configured: []) do
			searcher = Struct.new(:results).new([
				OpenStruct.new(author: 'Jonathn Logan; Olson, Jonathan R')
			])

			assert_equal ['Jonathan'], spell_check_from_searchers('Jonathn', [searcher])
		end
	end

	private

	def with_stubbed_names(names)
		with_stubbed_name_sources(webnodes: names, configured: []) do
			yield
		end
	end

	def with_stubbed_name_sources(webnodes:, configured:)
		names_dictionary_backup = @names_dictionary if instance_variable_defined?(:@names_dictionary)
		remove_instance_variable(:@names_dictionary) if instance_variable_defined?(:@names_dictionary)

		stubbed_webnodes = webnodes
		stubbed_configured = configured
		singleton_class.class_eval do
			define_method(:cached_webnodes_names_dictionary) { stubbed_webnodes }
			define_method(:configured_names_dictionary) { stubbed_configured }
		end

		yield
	ensure
		singleton_class.class_eval do
			remove_method(:cached_webnodes_names_dictionary) if method_defined?(:cached_webnodes_names_dictionary)
			remove_method(:configured_names_dictionary) if method_defined?(:configured_names_dictionary)
		end

		if names_dictionary_backup
			@names_dictionary = names_dictionary_backup
		elsif instance_variable_defined?(:@names_dictionary)
			remove_instance_variable(:@names_dictionary)
		end
	end
end

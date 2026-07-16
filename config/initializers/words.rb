words = File.join Rails.root, "/config/words.yml"
DICTIONARY = YAML.load_file(words)

SPELL_CHECKER = FFI::Hunspell.dict('en_US')
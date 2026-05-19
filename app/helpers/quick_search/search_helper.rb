module QuickSearch::SearchHelper
    def strip_character(string, character)
        string.gsub(/#{character}+$/, "").gsub(/#{character}+/, "")
    end

    def spell_check(params_q_scrubbed)
        if !params_q_scrubbed
          return []
        end
        canonical_name = best_name_phrase_suggestion(params_q_scrubbed)
        return [canonical_name] if canonical_name.present?

        query_clean = params_q_scrubbed.downcase
        if DICTIONARY.include?(query_clean)
          corrections = []
        else
          query_list = query_clean.split(' ')
          corrections = SPELL_CHECKER.check?(query_clean) ? [] : SPELL_CHECKER.suggest(query_clean)
          multiwordcheck = (query_clean.length - corrections.join(" ").length).abs() > 2
          multiwordcheck = multiwordcheck ? multiwordcheck : !query_list.any? { |word| corrections.join(" ").include?(word) }

          corrections = multiwordcheck ? [] : corrections
          if corrections.length == 0 || multiwordcheck
            correction = []
            query_list.each do | q |
              if !DICTIONARY.include?(q) && q.length > 2
                checker = SPELL_CHECKER.check?(q) ? q : preferred_suggestion(q)
                check = checker.present? ? (q.length - checker.length).abs() : 3
                check2 = checker.present? ? (checker.chars - q.chars).concat(q.chars - checker.chars).uniq.count : 4
                if check > 2 || check2 > 3
                  correction.push(q)
                else
                  correction.push(checker)
                end
              else
                correction.push(q)
              end
            end
            corrections = [correction.join(' ')] if correction.join(' ') != query_clean else []
          end
        end
        return corrections
    end

    def spell_check_from_searchers(params_q_scrubbed, searchers)
      return [] if params_q_scrubbed.blank?

      phrase_candidates, token_candidates = search_result_name_candidates(searchers)
      candidates = params_q_scrubbed.to_s.split.size > 1 ? phrase_candidates : token_candidates
      normalized_query = normalize_for_matching(params_q_scrubbed)
      filtered_candidates = candidates.reject do |candidate|
        normalize_for_matching(candidate) == normalized_query
      end
      suggestion = best_name_suggestion(params_q_scrubbed, name_candidates_for(params_q_scrubbed, filtered_candidates))

      suggestion.present? ? [suggestion] : []
    end

    private

    # Pick the suggestion with the smallest Levenshtein distance to the original word.
    # This produces better results than taking Hunspell's first suggestion, which is
    # ranked by Hunspell's internal phonetic scoring rather than edit distance.
    def best_hunspell_suggestion(word, suggestions)
      return nil if suggestions.empty?
      suggestions.min_by { |s| levenshtein_distance(word, s) }
    end

    def preferred_suggestion(word)
      name_suggestion = best_name_token_suggestion(word)
      hunspell_suggestion = best_hunspell_suggestion(word, SPELL_CHECKER.suggest(word))

      return name_suggestion if prefer_name_suggestion?(word, name_suggestion, hunspell_suggestion)

      hunspell_suggestion
    end

    def prefer_name_suggestion?(word, name_suggestion, hunspell_suggestion)
      return false if name_suggestion.blank?
      return true if hunspell_suggestion.blank?

      levenshtein_distance(normalize_for_matching(word), normalize_for_matching(name_suggestion)) <=
        levenshtein_distance(normalize_for_matching(word), normalize_for_matching(hunspell_suggestion))
    end

    def best_name_phrase_suggestion(query)
      return nil if query.blank?

      candidates = name_candidates_for(query, names_dictionary)
      best_name_suggestion(query, candidates)
    end

    def best_name_token_suggestion(word)
      return nil if word.blank?

      candidates = name_candidates_for(word, names_dictionary.flat_map { |name| name.split(/\s+/) }.uniq)
      best_name_suggestion(word, candidates)
    end

    def best_name_suggestion(term, candidates)
      return nil if candidates.empty?

      candidate = candidates.min_by do |value|
        levenshtein_distance(normalize_for_matching(term), normalize_for_matching(value))
      end

      acceptable_name_match?(term, candidate) ? candidate : nil
    end

    def name_candidates_for(term, candidates)
      term_token_count = term.to_s.split.size
      return candidates if term_token_count <= 1

      matching_candidates = candidates.select { |candidate| candidate.to_s.split.size == term_token_count }
      matching_candidates.presence || candidates
    end

    def acceptable_name_match?(term, candidate)
      return false if candidate.blank?

      normalized_term = normalize_for_matching(term)
      normalized_candidate = normalize_for_matching(candidate)
      return false if normalized_term == normalized_candidate

      distance = levenshtein_distance(normalized_term, normalized_candidate)
      max_distance = [1, normalized_term.length / 4].max

      distance <= max_distance
    end

    def normalize_for_matching(value)
      value.to_s.downcase.gsub(/[^a-z0-9]/, '')
    end

    def names_dictionary
      @names_dictionary ||= begin
        (cached_webnodes_names_dictionary + configured_names_dictionary).uniq
      end
    end

    def cached_webnodes_names_dictionary
      return [] if webnodes_solr_url.blank?

      Rails.cache.fetch('quick_search/spell_check/webnodes_names', expires_in: 12.hours) do
        webnodes_names_dictionary
      end
    rescue StandardError
      []
    end

    def webnodes_names_dictionary
      solr = RSolr.connect url: webnodes_solr_url
      response = solr.get 'select', params: {
        'q' => 'type:staff',
        'fl' => 'firstname,lastname',
        'rows' => 2000,
        'sort' => 'lastname asc, firstname asc'
      }

      Array(response.dig('response', 'docs')).filter_map do |doc|
        first_name = Array(doc['firstname']).first.to_s.strip
        last_name = Array(doc['lastname']).first.to_s.strip
        next if first_name.blank? || last_name.blank?

        "#{first_name} #{last_name}"
      end.uniq
    end

    def webnodes_solr_url
      QuickSearch::Engine::WEBNODES_CONFIG['solr_url']
    rescue NameError, NoMethodError
      nil
    end

    def configured_names_dictionary
      config_path = File.join(Rails.root, 'config', 'names.yml')
      return [] unless File.exist?(config_path)

      config = YAML.load_file(config_path)
      values = if config.is_a?(Hash)
                 config['names'] || config[:names] || []
               elsif config.is_a?(Array)
                 config
               else
                 []
               end

      values.map(&:to_s).map(&:strip).reject(&:blank?).uniq
    end

    def search_result_name_candidates(searchers)
      phrase_candidates = []
      token_candidates = []

      Array(searchers).each do |searcher|
        next if searcher.blank? || searcher.is_a?(StandardError) || searcher.results.blank?

        searcher.results.first(5).each do |result|
          phrase_candidates.concat(author_phrase_candidates(result))
          token_candidates.concat(author_token_candidates(result))
        end
      end

      [phrase_candidates.uniq, token_candidates.uniq]
    end

    def author_phrase_candidates(result)
      author_values(result).filter_map do |author_value|
        normalize_author_phrase(author_value)
      end
    end

    def author_token_candidates(result)
      author_values(result).flat_map do |author_value|
        normalize_author_phrase(author_value).to_s.scan(/\b[A-Z][a-z]{2,}\b/)
      end.uniq
    end

    def author_values(result)
      result_hash = result.respond_to?(:to_h) ? result.to_h : {}
      author = result_hash['author'] || result_hash[:author]
      author.present? ? author.to_s.split(';').map(&:strip).reject(&:blank?) : []
    end

    def normalize_author_phrase(author_value)
      if author_value.include?(',')
        parts = author_value.split(',').map(&:strip).reject(&:blank?)
        return nil if parts.empty?

        ([parts[1..].join(' '), parts.first].reject(&:blank?).join(' ')).squeeze(' ')
      else
        author_value.squeeze(' ')
      end
    end

    def levenshtein_distance(s, t)
      m, n = s.length, t.length
      d = Array.new(m + 1) { Array.new(n + 1, 0) }
      (0..m).each { |i| d[i][0] = i }
      (0..n).each { |j| d[0][j] = j }
      (1..n).each do |j|
        (1..m).each do |i|
          cost = s[i-1] == t[j-1] ? 0 : 1
          d[i][j] = [d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + cost].min
        end
      end
      d[m][n]
    end
end

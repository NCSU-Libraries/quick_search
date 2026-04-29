module QuickSearch::SearchHelper
    def strip_character(string, character)
        string.gsub(/#{character}+$/, "").gsub(/#{character}+/, "")
    end

    def spell_check(params_q_scrubbed)
        if !params_q_scrubbed
          return []
        end
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
                checker = SPELL_CHECKER.check?(q) ? q : best_hunspell_suggestion(q, SPELL_CHECKER.suggest(q))
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

    private

    # Pick the suggestion with the smallest Levenshtein distance to the original word.
    # This produces better results than taking Hunspell's first suggestion, which is
    # ranked by Hunspell's internal phonetic scoring rather than edit distance.
    def best_hunspell_suggestion(word, suggestions)
      return nil if suggestions.empty?
      suggestions.min_by { |s| levenshtein_distance(word, s) }
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

module QuickSearch::SearchHelper
    def stripcharacter(string, character)
        string.gsub(/#{character}+$/, "").gsub(/#{character}+/, "")
    end

    def corrections(params_q_scrubbed)
        if !params_q_scrubbed
          return []
        end
        query_clean = params_q_scrubbed.downcase
        if DICTIONARY.include?(query_clean)
          corrections = []
        else
          corrections = SPELL_CHECKER.correct(query_clean)
          if corrections.length == 0
            correction = []
            query_clean.split(' ').each do | q |
              if !DICTIONARY.include?(q)
                correction.push(SPELL_CHECKER.correct(q).first)
              else
                correction.push(q)
              end
            end
            corrections = [correction.join(' ')] if correction.join(' ') != query_clean else []
          end
        end
        return corrections
    end
end

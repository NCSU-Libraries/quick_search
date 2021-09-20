module QuickSearch::SearchHelper
    def stripcharacter(string, character)
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
          corrections = SPELL_CHECKER.correct(query_clean)
          multiwordcheck = (query_clean.length - corrections.join(" ").length).abs() > 2
          multiwordcheck = multiwordcheck ? multiwordcheck : !query_list.any? { |word| corrections.join(" ").include?(word) }

          corrections = multiwordcheck ? [] : corrections
          if corrections.length == 0 || multiwordcheck
            correction = []
            query_list.each do | q |
              if !DICTIONARY.include?(q)
                checker = SPELL_CHECKER.correct(q).first
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
end

function [ word_hash ] = word_hash( word )
% 2014/03/29: matlab version of word hash function
% **** MUST KEEP AS THE SAME VERSION AS THE ONE IN PYTHON ***
    

    word_hash = regexprep(word,'(.)\1+','$1');

    % update word as after removing repeated characters
    end_is_removed = 0; 
    if (end_is_removed == 0 && length(word_hash) > 3),
        word_end = word_hash(length(word_hash)-3+1:length(word_hash));
        if(all(word_end == 'ied') || all(word_end == 'ies')),
            word_hash = word_hash(1:length(word_hash)-3);
            end_is_removed = 1;
        end
    end
    
    if (end_is_removed == 0 && length(word_hash) > 2),
        word_end = word_hash(length(word_hash)-2+1:length(word_hash));
        if(all(word_end == 'ed') || all(word_end == 'es')),
            word_hash = word_hash(1:length(word_hash)-2);
            end_is_removed = 1;
        end
    end
    
    if (end_is_removed == 0 && length(word_hash) > 1),
        word_end = word_hash(length(word_hash)-1+1:length(word_hash));
        if(all(word_end == 'd') || all(word_end == 's' || all(word_end == 'y'))),
            word_hash = word_hash(1:length(word_hash)-1);
            end_is_removed = 1;
        end
    end
    
end


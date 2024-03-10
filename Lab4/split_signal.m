function splitted_signal = split_signal(signal, num_segments)
    
    len_signal = length(signal);
    len_split = floor(len_signal / num_segments);
    
    % Sørge for at antall deler ikke er større enn lengden på signalet
    if len_split == 0
        error('Antallet deler er større enn lengden på signalet.');
    end
    
    % Splitte signalet inn i M like lange deler
    splitted_signal = cell(1, num_segments);
    for i = 1:num_segments
        start_idx = (i - 1) * len_split + 1;
        end_idx = min(i * len_split, len_signal);
        splitted_signal{i} = signal(start_idx:end_idx);
    end
end


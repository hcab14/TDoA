## -*- octave -*-

function d=kiwi_info(dir)
  files = glob([dir filesep() '*.txt']);
  for i=1:length(files)
    try
      source(files{i});
    catch err
      error(sprintf('%s: %s', files{i}, err.message))
    end_try_catch
  end
end

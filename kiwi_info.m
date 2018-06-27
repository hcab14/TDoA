## -*- octave -*-

function d=kiwi_info()
  files = glob('gnss_pos/*.txt');
  for i=1:length(files)
    try
      source(files{i});
    catch err
      error(sprintf('%s: %s', files{i}, err.message))
    end_try_catch
  end
end


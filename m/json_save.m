## -*- octave -*-

## limited octave value -> JSON converter

function json_save(fid, obj)
  ## for perfomance reasons we use an array of tab characters
  ## this limits the depths of data structures to 256
  TAB = char(sprintf('\t')*ones(1,256, 'uint8'));

  ## call the main sub-function
  json_save_object(fid, obj, 0);
  fprintf(fid, '\n');

  function json_save_object(fid, obj, lvl)
    n  = numel(obj);
    if isstruct(obj)
      fns = fieldnames(obj);
      m   = numfields(obj);
      if n == 1
        fprintf(fid, '{\n');
        json_save_struct(fid, obj, lvl+1, fns, m);
        fprintf(fid, '%s}', TAB(1:lvl));
      else
        fprintf(fid, '[\n');
        if false
          arrayfun(@(x) struct_helper(fid, x, lvl+1, false, fns, m), obj(1:end-1));
          struct_helper(fid, obj(end), lvl+1, true, fns, m);
        else
          lvl+=1;
          for i=1:n
            fprintf(fid, '%s{\n', TAB(1:lvl));
            json_save_struct(fid, obj(i), lvl+1, fns, m);
            if i==n
              fprintf(fid, '%s}\n', TAB(1:lvl)),
            else
              fprintf(fid, '%s},\n', TAB(1:lvl)),
            end
          end
          lvl-=1;
        end
        fprintf(fid, '%s]', TAB(1:lvl));
      end
    elseif iscell(obj)
      if n==0
        fprintf(fid, '[]');
      else
        fprintf(fid, '[\n\t%s', TAB(1:lvl));
        for i=1:n
          json_save_object(fid, obj{i}, lvl+1);
          if i==n
            fprintf(fid, '\n', TAB(1:lvl));
          else
            fprintf(fid, ',\n%s', TAB(1:lvl+1));
          end
        end
        fprintf(fid, '%s]', TAB(1:lvl));
      end
    elseif is_sq_string(obj)
      fprintf(fid, '"%s"', obj);
    elseif n>1 && ismatrix(obj)
      if any(isinf(obj))
        fprintf(fid, replace_inf(['[' sprintf("%g, ", obj)(1:end-2) ']']));
      else
        fprintf(fid, ['[' sprintf("%g,", obj)(1:end-1) ']']);
      end
    elseif isnumeric(obj)
      if isempty(obj)
        fprintf(fid, '[]');
      elseif isinf(obj)
        fprintf(fid, replace_inf(sprintf('%g', obj)));
      else
        fprintf(fid, '%g', obj);
      end
    end
    function struct_helper(fid, obj, lvl, c, fns, m)
      fprintf(fid, '%s{\n', TAB(1:lvl));
      json_save_struct(fid, obj, lvl+1, fns, m);
      if c
        fprintf(fid, '%s}\n', TAB(1:lvl)),
      else
        fprintf(fid, '%s},\n', TAB(1:lvl)),
      end
    endfunction
  endfunction
  function json_save_struct(fid, s, lvl, fns, n)
    for i=1:n
      fprintf(fid, '%s"%s": ', TAB(1:lvl), fns{i});
      json_save_object(fid, s.(fns{i}), lvl);
      if i!=n
        fprintf(fid, ',\n');
      else
        fprintf(fid, '\n');
      end
    end
  endfunction
    function s=replace_inf(s)
      s = strrep(s, 'Inf', '"Infinity"');
      s = strrep(s, '-"Inf', '"-Inf');
    endfunction
endfunction



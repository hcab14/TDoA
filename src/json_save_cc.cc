#include <octave/oct.h>
#include <octave/interpreter.h>

void oct_printf(octave::stream& s, std::string fmt, octave_value const& ov=octave_value()) {
  s.printf(fmt, ov, "");
}

void print_tabs(octave::stream& s, int lvl) {
  for (int i=0; i<lvl; ++i)
    oct_printf(s, "\t");
}

void json_save_object(octave::stream& s, octave_value const& ov, int lvl);

void json_save_struct(octave::stream& s, octave_map const& map, int lvl, octave_idx_type idx=0) {
  oct_printf(s, "{\n");
  for (octave_map::const_iterator i=map.begin(), iend=map.end(); i!=iend;) {
    print_tabs(s, lvl);
    oct_printf(s, "\"%s\": ", map.key(i).c_str());
    json_save_object(s, map.contents(i)(idx), lvl);
    octave_map::const_iterator j = ++i;
    if (j == iend)
      oct_printf(s, "\n");
    else
      oct_printf(s, ",\n");
  }
  print_tabs(s, lvl-1);
  oct_printf(s, "}");
}

void json_save_num(octave::stream& s, octave_value const& ov, bool islogical=false) {
  if (ov.islogical() || islogical) {
    oct_printf(s, ov.bool_value() ? "true" : "false");
  } else if (ov.isinf().bool_value()) {
    oct_printf(s, (ov > 0).bool_value() ? "\"Infinity\"" : "\"-Infinity\"");
  } else if (ov.isnan().bool_value()) {
    oct_printf(s, "\"NaN\"");
  } else {
    oct_printf(s, "%g", ov);
  }
}
void json_save_object(octave::stream& s, octave_value const& ov, int lvl) {
  octave_idx_type const n = ov.numel();
  if (n == 0) {
    oct_printf(s, "[]");
  } else if (ov.isstruct()) {
    if (n == 1) {
      json_save_struct(s, ov.map_value(), lvl+1, 0);
    } else {
      oct_printf(s, "[\n");
      for (octave_idx_type i=0; i<n; ++i) {
        print_tabs(s, lvl+1);
        json_save_struct(s, ov.map_value(), lvl+2, i);
        if (i+1 == n) {
          oct_printf(s, "\n");
        } else {
          oct_printf(s, ",\n");
        }
      }
      print_tabs(s, lvl);
      oct_printf(s, "]");
    }
  } else if (ov.iscell()) {
    oct_printf(s, "[\n");
    print_tabs(s, lvl+1);
    for (octave_idx_type i=0; i<n; ++i) {
      json_save_object(s, ov.list_value()(i), lvl+1);
      if (i+1 == n) {
        oct_printf(s, "\n");
      } else {
        oct_printf(s, ",\n");
        print_tabs(s, lvl+1);
      }
    }
    print_tabs(s, lvl);
    oct_printf(s, "]");
  } else if (ov.is_sq_string()) {
    std::string const str = octave::regexp::replace("\"", ov.string_value(), "\\\\\"");
    oct_printf(s, "\"%s\"", str.c_str());
  } else if (ov.is_dq_string()) {
    oct_printf(s, "\"%s\"", ov);
  } else if (ov.is_matrix_type() && n>1) {
    oct_printf(s, "[");
    for (octave_idx_type i=0; i<n; ++i) {
      json_save_num(s, ov.islogical() ? ov.bool_array_value()(i) : ov.array_value()(i),
                    ov.islogical());
      if (i+1 < n)
        oct_printf(s, ",");
    }
    oct_printf(s, "]");
  } else if (ov.is_scalar_type()) {
    json_save_num(s, ov);
  }
}

DEFUN_DLD (json_save_cc,
           args,
           ,
           "Usage: json_save_cc(fid, obj);")
{
  octave_value_list retval;
  int const nargin(args.length());
  if (nargin != 2) {
    print_usage();
    return retval;
  }
  octave::interpreter *interp = octave::interpreter::the_interpreter();
  if (!interp)
    error("no octave interpreter found");
  octave::stream s = interp->get_stream_list().lookup(args(0));

  json_save_object(s, args(1), 0);
  oct_printf(s, "\n");
  return retval;
}


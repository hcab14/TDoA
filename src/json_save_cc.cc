#include <octave/oct.h>

#if (OCTAVE_MAJOR_VERSION >= 4 and OCTAVE_MINOR_VERSION >= 4) or OCTAVE_MAJOR_VERSION >= 5
#  include <octave/interpreter.h>
#  define OCT_STREAM_TYPE    octave::stream
#  define OCT_REGEXP_REPLACE octave::regexp::replace
OCT_STREAM_TYPE get_stream(octave_value ov) {
  octave::interpreter *interp = octave::interpreter::the_interpreter();
  if (!interp)
    error("no octave interpreter found");
  return interp->get_stream_list().lookup(ov);
}
#else
#  include <octave/oct-map.h>
#  include <octave/oct-stream.h>
#  define OCT_VERSION_LESS_THAN_4_4
#  define OCT_STREAM_TYPE octave_stream
#  if OCTAVE_MINOR_VERSION >= 2
#    define OCT_REGEXP_REPLACE octave::regexp::replace
#  else
#    define OCT_VERSION_LESS_THAN_4_2
#    define OCT_REGEXP_REPLACE regexp_replace
#  endif
OCT_STREAM_TYPE get_stream(octave_value ov) {
  return octave_stream_list::lookup(ov);
}
#endif

void oct_printf(OCT_STREAM_TYPE& s, std::string fmt, octave_value const& ov=octave_value()) {
  s.printf(fmt, ov, "");
}

void print_tabs(OCT_STREAM_TYPE& s, bool sep, int lvl) {
  if (!sep)
    return;
  for (int i=0; i<lvl; ++i)
    oct_printf(s, "\t");
}

void json_save_object(OCT_STREAM_TYPE& s, bool sep, octave_value ov, int lvl);

void json_save_struct(OCT_STREAM_TYPE& s, bool sep, octave_map const& map, int lvl, octave_idx_type idx=0) {
  oct_printf(s, "{%s", sep ? "\n" : "");
  for (octave_map::const_iterator i=map.begin(), iend=map.end(); i!=iend;) {
    print_tabs(s, sep, lvl);
    oct_printf(s, "\"%s\":", map.key(i).c_str());
    if (sep)
      oct_printf(s, " ");
    json_save_object(s, sep, map.contents(i)(idx), lvl);
    octave_map::const_iterator const j = ++i;
    if (j == iend)
      oct_printf(s, "%s", sep ? "\n" : "");
    else
      oct_printf(s, ",%s", sep ? "\n" : "");
  }
  print_tabs(s, sep, lvl-1);
  oct_printf(s, "}");
}

void json_save_string(OCT_STREAM_TYPE& s, bool sep, std::string str, int lvl) {
  std::size_t found = str.find("\n");
  if (found == std::string::npos) {
    oct_printf(s, "\"%s\"", str.c_str());
    return;
  }
  octave_value_list c;
  int i=0;
  while (found != std::string::npos) {
    c(i++) = str.substr(0, found);
    str = str.substr(found+1, std::string::npos);
    found = str.find("\n");
  }
  c(i) = str;
  octave_value ov(c.cell_value());
  json_save_object(s, sep, ov, lvl);
}

void json_save_num(OCT_STREAM_TYPE& s, bool sep, octave_value const& ov, bool islogical=false) {
#ifdef OCT_VERSION_LESS_THAN_4_4
  if (ov.is_bool_type() || islogical) {
#else
  if (ov.islogical() || islogical) {
#endif
    oct_printf(s, ov.bool_value() ? "true" : "false");
  } else if (ov.isinf().bool_value()) {
    oct_printf(s, (ov > 0).bool_value() ? "\"Infinity\"" : "\"-Infinity\"");
  } else if (ov.isnan().bool_value()) {
    oct_printf(s, "\"NaN\"");
  } else {
    oct_printf(s, "%g", ov);
  }
}
void json_save_object(OCT_STREAM_TYPE& s, bool sep, octave_value ov, int lvl) {
  octave_idx_type const n = ov.numel();
  if (n == 0) {
    oct_printf(s, ov.is_string() ? "\"\"" : "[]");
#ifdef OCT_VERSION_LESS_THAN_4_4
  } else if (ov.is_map()) {
#else
  } else if (ov.isstruct()) {
#endif
    if (n == 1) {
      json_save_struct(s, sep, ov.map_value(), lvl+1, 0);
    } else {
      oct_printf(s, "[%s", sep ? "\n" : "");
      for (octave_idx_type i=0; i<n; ++i) {
        print_tabs(s, sep, lvl+1);
        json_save_struct(s, sep, ov.map_value(), lvl+2, i);
        if (i+1 != n) {
          oct_printf(s, ",");
        }
        if (sep)
          oct_printf(s, "\n");
      }
      print_tabs(s, sep, lvl);
      oct_printf(s, "]");
    }
#ifdef OCT_VERSION_LESS_THAN_4_4
  } else if (ov.is_cell()) {
#else
  } else if (ov.iscell()) {
#endif
    oct_printf(s, "[%s", sep ? "\n" : "");
    print_tabs(s, sep, lvl+1);
    for (octave_idx_type i=0; i<n; ++i) {
      json_save_object(s, sep, ov.list_value()(i), lvl+1);
      if (i+1 == n) {
        oct_printf(s, "%s", sep ? "\n" : "");
      } else {
        oct_printf(s, ",%s", sep ? "\n" : "");
        print_tabs(s, sep, lvl+1);
      }
    }
    print_tabs(s, sep, lvl);
    oct_printf(s, "]");
  } else if (ov.is_sq_string()) {
    std::string const str = OCT_REGEXP_REPLACE("\"", ov.string_value(), "'");
    json_save_string(s, sep, str, lvl);
  } else if (ov.is_dq_string()) {
    json_save_string(s, sep, ov.string_value(), lvl);
  } else if (ov.is_matrix_type() && n>1) {
    oct_printf(s, "[");
    for (octave_idx_type i=0; i<n; ++i) {
#ifdef OCT_VERSION_LESS_THAN_4_4
      json_save_num(s, sep, ov.is_bool_type() ? ov.bool_array_value()(i) : ov.array_value()(i),
                    ov.is_bool_type());
#else
      json_save_num(s, sep, ov.islogical() ? ov.bool_array_value()(i) : ov.array_value()(i),
                    ov.islogical());
#endif
      if (i+1 < n)
        oct_printf(s, ",");
    }
    oct_printf(s, "]");
  } else if (ov.is_scalar_type()) {
    json_save_num(s, sep, ov);
  }
}

DEFUN_DLD (json_save_cc,
           args,
           ,
           "Usage: json_save_cc(fid, obj, sep); sep is optional:\n default is sep == true ... tab/space/crlf, sep == false ... compact")
{
  octave_value_list retval;
  int const nargin(args.length());
  if (nargin < 2 || nargin > 3) {
    print_usage();
    return retval;
  }
  bool const sep = (nargin == 3 ? args(2).bool_value() : true);
  OCT_STREAM_TYPE s = get_stream(args(0));
  json_save_object(s, sep, args(1), 0);
  oct_printf(s, "\n");
  return retval;
}


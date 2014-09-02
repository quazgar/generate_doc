## Copyright (C) 2008 Soren Hauberg <soren@hauberg.org>
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{index} =} txi2index (@var{file_pattern})
## Convert @code{.txi} files in the Octave source into an @t{INDEX} structure
## suitable for generating a functon reference.
##
## @var{file_pattern} must be a string containing either the name of a @code{.txi}
## file, or a pattern for globbing a set of files (e.g. @t{"*.txi"}). The resulting
## cell array @var{index} contains a set of structures corresponding to those
## generated by @code{pkg ("describe")}. These structures can then be given to
## @code{generate_package_html} to produce @t{HTML} content.
##
## As an example, if the Octave source code is located in @t{~/octave_code},
## then this function can be called with
##
## @example
## octave_source_code = "~/octave_code";
## index = txi2index (fullfile (octave_source_code, "doc/interpreter", "*.txi"));
## @end example
## @seealso{pkg, generate_package_html}
## @end deftypefn

function all_index = txi2index (srcdir)
  if (nargin == 0)
    print_usage ();
  endif

  if (!ischar (srcdir))
    error ("txi2index: input argument must be a string");
  endif

  file_list = get_txi_files (srcdir);

  all_index = cell (size (file_list));
  for k = 1:length (file_list)
    filename = file_list{k};

    [not_used, name] = fileparts (filename);
    index.filename = filename;
    index.name = name;
    index.description = "";
    index.provides = {};

    CHAPTER = "@chapter ";
    APPENDIX = "@appendix ";
    SECTION = "@section ";
    DOCSTRING = "@DOCSTRING";
    default_section = "General";

    fid = fopen (filename, "r");
    if (fid < 0)
      warning ("txi2index: couldn't open '%s' for reading", filename);
      continue;
    endif

    idx = 0;
    txi_has_contents = false;
    while (true)
      line = fgetl (fid);
      if (line == -1)
        break;
      endif

      if (strncmpi (CHAPTER, line, length (CHAPTER)))
        index.name = strtrim (line (length (CHAPTER)+1:end));
      elseif (strncmpi (APPENDIX, line, length (APPENDIX)))
        index.name = strtrim (line (length (APPENDIX)+1:end));
      elseif (strncmpi (SECTION, line, length (SECTION)))
        section = strtrim (line (length (SECTION)+1:end));
        if (idx == 0 || !isempty (index.provides {idx}.functions))
          idx ++;
        endif

        index.provides {idx} = struct ();
        index.provides {idx}.category = section;
        index.provides {idx}.functions = {};
      elseif (strncmpi (DOCSTRING, line, length (DOCSTRING)))
        if (idx == 0)
          idx ++;

          index.provides {idx} = struct ();
          index.provides {idx}.category = default_section;
          index.provides {idx}.functions = {};
        endif

        start = find (line == "(", 1);
        stop = find (line == ")", 1);
        if (isempty (start) || isempty (stop))
          warning ("txi2index: invalid @DOCSTRING: %s", line);
          continue;
        endif

        fun = strtrim (line (start+1:stop-1));
        index.provides {idx}.functions {end+1} = fun;
        txi_has_contents = true;
      endif
    endwhile
    fclose (fid);

    if (idx > 0 && isempty (index.provides {idx}.functions))
      index.provides = index.provides (1:idx-1);
    endif

    if (txi_has_contents)
      all_index {k} = index;
    else
      all_index {k} = [];
    endif
  endfor
endfunction

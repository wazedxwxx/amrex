#
#
# FUNCTION: get_amrex_version
#
# Retrieves AMReX version info and sets internal cache variables
# AMREX_GIT_VERSION and AMREX_PKG_VERSION
#
#
function (get_amrex_version)

   find_package(Git QUIET)

   set( _tmp "" )

   # Try to inquire software version from git
   if ( EXISTS ${CMAKE_CURRENT_LIST_DIR}/.git AND ${GIT_FOUND} )
      execute_process ( COMMAND git describe --abbrev=12 --dirty --always --tags
         WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
         OUTPUT_VARIABLE _tmp )
      string( STRIP ${_tmp} _tmp )
      # filter invalid descriptions in shallow git clones
      if (NOT _tmp MATCHES "^([0-9]+)\\.([0-9]+)(\\.([0-9]+))*(-.*)*$")
         set( _tmp "")
      endif ()
   endif()

   # Grep first line from file CHANGES if cannot find version from Git
   if (NOT _tmp)
      file(STRINGS ${CMAKE_CURRENT_LIST_DIR}/CHANGES ALL_VERSIONS REGEX "#")
      list(GET ALL_VERSIONS 0 _tmp)
      string(REPLACE "#" "" _tmp "${_tmp}")
      string(STRIP "${_tmp}" _tmp )
      set(_tmp "${_tmp}.0")
   endif ()

   set( AMREX_GIT_VERSION "${_tmp}" CACHE INTERNAL "" )
   unset(_tmp)

   # Package version is a modified form of AMREX_GIT_VERSION
   if (AMREX_GIT_VERSION)
      string(FIND "${AMREX_GIT_VERSION}" "-" _idx REVERSE)
      string(SUBSTRING "${AMREX_GIT_VERSION}" 0 "${_idx}" _pkg_version )
      string(FIND "${_pkg_version}" "-" _idx REVERSE)
      string(SUBSTRING "${_pkg_version}" 0 "${_idx}" _pkg_version )
      string(REPLACE "-" "." _pkg_version "${_pkg_version}")
   endif ()

   set( AMREX_PKG_VERSION "${_pkg_version}" CACHE INTERNAL "" )
   unset(_pkg_version)

endfunction ()


#
#
# FUNCTION: print
#
# Debug function to print a variable
#
# Arguments:
#
#    _var = the variable to print
#
#
function ( print _var )
   message(" ${_var} = ${${_var}}" )
endfunction ()

#
#
# FUNCTION: print_list
#
# Debug function to print a list as an columns of entries
#
# Arguments:
#
#    _list = the list to print
#
#
function ( print_list _list )

   list( LENGTH ${_list} _len )

   if ( ${_len} GREATER 0 )
      message("")
      message( STATUS "LIST NAME:  ${_list}")
      foreach ( _item ${${_list}})
         message ( STATUS "  ${_item}")
      endforeach ()
      message("")
   endif ()

endfunction ()


#
#
# FUNCTION: set_default_config_flags
#
#
# Set CMake_<LANG>_FLAGS_<CONFIG> to default values
# if the variable is empty
#
macro ( set_default_config_flags )

  if ( NOT CMAKE_Fortran_FLAGS_DEBUG )
    set (CMAKE_Fortran_FLAGS_DEBUG "-g")
  endif ()

  if ( NOT CMAKE_Fortran_FLAGS_RELEASE )
    set (CMAKE_Fortran_FLAGS_RELEASE "-O2")
  endif ()

  if ( NOT CMAKE_CXX_FLAGS_DEBUG )
    set (CMAKE_CXX_FLAGS_DEBUG "-g")
  endif ()

  if ( NOT CMAKE_CXX_FLAGS_RELEASE )
    set (CMAKE_CXX_FLAGS_RELEASE "-O2 -DNDEBUG")
  endif ()

endmacro ()

#
#
# FUNCTION: add_amrex_define
#
# Add definition to target "amrex" compile definitions.
#
# Arguments:
#
#    new_define    = variable containing the definition to add.
#                    The new define can be any string with no "-D" prepended.
#                    If the new define is in the form AMREX_SOMENAME,
#                    this function also adds BL_SOMENAME to the list,
#                    unless NO_LEGACY is specified (see below)
#
#    NO_LEGACY     = if specified, the legacy version of a new_define given in the
#                    form AMREX_SOMENAME will not be added.
#
#    IF <cond-var> = new_define is added only if <cond-var> is true
#
#
function ( add_amrex_define new_define )

   #
   # Check if target "amrex" has been defined before
   # calling this macro
   #
   if (NOT TARGET amrex)
      message(FATAL_ERROR "Target 'amrex' must be defined before calling function 'add_amrex_define'" )
   endif ()

   cmake_parse_arguments( DEFINE "NO_LEGACY" "IF" ""  ${ARGN} )

   set( condition  1 )

   if (DEFINE_IF)
      set( condition ${${DEFINE_IF}} )
   endif()

   # Return if flags does not need to be included
   if (NOT condition)
      return()
   endif ()

   target_compile_definitions( amrex PUBLIC $<BUILD_INTERFACE:${new_define}> )

   if ( NOT DEFINE_NO_LEGACY )
      # Add legacy definition
      string( FIND ${new_define} "AMREX_" out )

      if (${out} GREATER -1 )
	 string(REPLACE "AMREX_" "BL_" legacy_define ${new_define})
	 target_compile_definitions( amrex PUBLIC $<BUILD_INTERFACE:${legacy_define}> )
      endif ()
   endif ()

endfunction ()


#
#
# FUNCTION: set_mininum_cxx_compiler_version
#
# Check whether the C++ compiler version is >= a required minimum.
# If not, stop with a fatal error
#
# Arguments:
#
#    _comp_id         = the compiler ID
#    _minimum_version = the minimum version required for _comp_id
#
#
function (set_mininum_cxx_compiler_version _comp_id  _minimum_version)
   if (  (CMAKE_CXX_COMPILER_ID STREQUAL _comp_id ) AND
         (CMAKE_CXX_COMPILER_VERSION VERSION_LESS _minimum_version ) )
      message( FATAL_ERROR
         "\n${_comp_id} compiler version is ${CMAKE_CXX_COMPILER_VERSION}. Minimum required is ${_minimum_version}.\n")
   endif ()
endfunction ()

# Writes the gzipped man page of a program from its --help output with help2man.
# cmake -DHELP2MAN=<help2man> -DPROGRAM=<path> -DVERSION=<x.y.z> -DOUTPUT=<page.1.gz>
#   -P ValhallaManPage.cmake
# The NAME line is the first sentence of the description the program prints, so the page only
# says what the program itself says.
get_filename_component(name "${PROGRAM}" NAME)

execute_process(COMMAND "${PROGRAM}" --help OUTPUT_VARIABLE help RESULT_VARIABLE result)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "${PROGRAM} --help failed: ${result}")
endif()

# the description is the first paragraph that is neither the "name version" banner nor a usage
string(REPLACE ";" "\\;" help "${help}")
string(REPLACE "\n" ";" lines "${help}")
set(description "")
set(skip_paragraph FALSE)
foreach(line IN LISTS lines)
  string(STRIP "${line}" line)
  if(line STREQUAL "")
    if(NOT description STREQUAL "")
      break()
    endif()
    set(skip_paragraph FALSE)
  elseif(skip_paragraph OR line STREQUAL "${name} ${VERSION}")
    continue()
  elseif(line MATCHES "^[Uu]sage:")
    if(NOT description STREQUAL "")
      break()
    endif()
    set(skip_paragraph TRUE)
  else()
    string(APPEND description " ${line}")
  endif()
endforeach()

string(REGEX REPLACE "[ \t]+" " " description "${description}")
string(REGEX REPLACE "^ (${name} is )?" "" description "${description}")
string(REGEX REPLACE "\\.( .*)?$" "" description "${description}")
if(description STREQUAL "")
  message(FATAL_ERROR "${PROGRAM} --help prints no description")
endif()

string(REGEX REPLACE "\\.gz$" "" page "${OUTPUT}")
execute_process(
  COMMAND "${HELP2MAN}" --no-info "--version-string=${VERSION}" "--name=${description}"
    "--output=${page}" "${PROGRAM}"
  RESULT_VARIABLE result)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "help2man failed on ${PROGRAM}")
endif()
execute_process(COMMAND gzip -9nf "${page}" RESULT_VARIABLE result)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "gzip failed on ${page}")
endif()

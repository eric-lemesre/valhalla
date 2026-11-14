#include "argparse_utils.h"
#include "baldr/rapidjson_utils.h"
#include "odin/worker.h"

#include <boost/property_tree/ptree.hpp>
#include <cxxopts.hpp>

#include <filesystem>
#include <iostream>

int main(int argc, char** argv) {
  const auto program = std::filesystem::path(__FILE__).stem().string();
  std::string config_file;

  try {
    // clang-format off
    cxxopts::Options options(
      program,
      program + " " + VALHALLA_PRINT_VERSION + "\n\n"
      "an odin worker of the distributed Valhalla service,\n"
      "which builds the maneuvers and the narrative of the routes.\n\n");

    options.add_options()
      ("h,help", "Print this help message.")
      ("v,version", "Print the version of this software.")
      ("CONFIG_JSON", "Path to the json configuration file.", cxxopts::value<std::string>(config_file));
    // clang-format on

    options.parse_positional({"CONFIG_JSON"});
    options.positional_help("CONFIG_JSON");
    auto result = options.parse(argc, argv);
    if (!parse_common_args(program, options, result, nullptr))
      return EXIT_SUCCESS;

    if (!result.count("CONFIG_JSON")) {
      std::cerr << options.help() << std::endl;
      return EXIT_FAILURE;
    }
  } catch (cxxopts::exceptions::exception& e) {
    std::cerr << e.what() << std::endl;
    return EXIT_FAILURE;
  }

  boost::property_tree::ptree config;
  rapidjson::read_json(config_file, config);

  // run the service worker
  valhalla::odin::run_service(config);

  return 0;
}

const packageConfigWithDirectAndTransitiveDependencies = '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "_fe_analyzer_shared",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/_fe_analyzer_shared-85.0.0",
      "packageUri": "lib/",
      "languageVersion": "3.5"
    },
    {
      "name": "analyzer",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/analyzer-7.7.1",
      "packageUri": "lib/",
      "languageVersion": "3.5"
    },
    {
      "name": "args",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/args-2.7.0",
      "packageUri": "lib/",
      "languageVersion": "3.3"
    },
    {
      "name": "async",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/async-2.13.0",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "boolean_selector",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/boolean_selector-2.1.2",
      "packageUri": "lib/",
      "languageVersion": "3.1"
    },
    {
      "name": "characters",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/characters-1.4.0",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "cli_config",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/cli_config-0.2.0",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "clock",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/clock-1.1.2",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "collection",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/collection-1.19.1",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "convert",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/convert-3.1.2",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "coverage",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/coverage-1.15.0",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "crypto",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/crypto-3.0.6",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "cupertino_icons",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.8",
      "packageUri": "lib/",
      "languageVersion": "3.1"
    },
    {
      "name": "dart_frog",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/dart_frog-1.2.3",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "fake_async",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/fake_async-1.3.3",
      "packageUri": "lib/",
      "languageVersion": "3.3"
    },
    {
      "name": "file",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/file-7.0.1",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "flutter",
      "rootUri": "file:///Users/felix/Development/github.com/flutter/flutter/packages/flutter",
      "packageUri": "lib/",
      "languageVersion": "3.8"
    },
    {
      "name": "flutter_lints",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/flutter_lints-5.0.0",
      "packageUri": "lib/",
      "languageVersion": "3.5"
    },
    {
      "name": "flutter_test",
      "rootUri": "file:///Users/felix/Development/github.com/flutter/flutter/packages/flutter_test",
      "packageUri": "lib/",
      "languageVersion": "3.8"
    },
    {
      "name": "frontend_server_client",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/frontend_server_client-4.0.0",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "glob",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/glob-2.1.3",
      "packageUri": "lib/",
      "languageVersion": "3.3"
    },
    {
      "name": "hotreloader",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/hotreloader-4.3.0",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "http_methods",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/http_methods-1.1.1",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    },
    {
      "name": "http_multi_server",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/http_multi_server-3.2.2",
      "packageUri": "lib/",
      "languageVersion": "3.2"
    },
    {
      "name": "http_parser",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/http_parser-4.1.2",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "io",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/io-1.0.5",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "js",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/js-0.7.2",
      "packageUri": "lib/",
      "languageVersion": "3.7"
    },
    {
      "name": "leak_tracker",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/leak_tracker-11.0.1",
      "packageUri": "lib/",
      "languageVersion": "3.2"
    },
    {
      "name": "leak_tracker_flutter_testing",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/leak_tracker_flutter_testing-3.0.10",
      "packageUri": "lib/",
      "languageVersion": "3.2"
    },
    {
      "name": "leak_tracker_testing",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/leak_tracker_testing-3.0.2",
      "packageUri": "lib/",
      "languageVersion": "3.2"
    },
    {
      "name": "lints",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/lints-5.1.1",
      "packageUri": "lib/",
      "languageVersion": "3.6"
    },
    {
      "name": "logging",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/logging-1.3.0",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "matcher",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/matcher-0.12.17",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "material_color_utilities",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/material_color_utilities-0.11.1",
      "packageUri": "lib/",
      "languageVersion": "2.17"
    },
    {
      "name": "meta",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/meta-1.16.0",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    },
    {
      "name": "mime",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/mime-2.0.0",
      "packageUri": "lib/",
      "languageVersion": "3.2"
    },
    {
      "name": "mocktail",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/mocktail-1.0.4",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    },
    {
      "name": "node_preamble",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/node_preamble-2.0.2",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    },
    {
      "name": "package_config",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/package_config-2.2.0",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "path",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/path-1.9.1",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "pool",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/pool-1.5.1",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    },
    {
      "name": "pub_semver",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/pub_semver-2.2.0",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "shelf",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/shelf-1.4.2",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "shelf_hotreload",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/shelf_hotreload-1.5.0",
      "packageUri": "lib/",
      "languageVersion": "2.17"
    },
    {
      "name": "shelf_packages_handler",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/shelf_packages_handler-3.0.2",
      "packageUri": "lib/",
      "languageVersion": "2.17"
    },
    {
      "name": "shelf_static",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/shelf_static-1.1.3",
      "packageUri": "lib/",
      "languageVersion": "3.3"
    },
    {
      "name": "shelf_web_socket",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/shelf_web_socket-3.0.0",
      "packageUri": "lib/",
      "languageVersion": "3.5"
    },
    {
      "name": "sky_engine",
      "rootUri": "file:///Users/felix/Development/github.com/flutter/flutter/bin/cache/pkg/sky_engine",
      "packageUri": "lib/",
      "languageVersion": "3.8"
    },
    {
      "name": "source_map_stack_trace",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/source_map_stack_trace-2.1.2",
      "packageUri": "lib/",
      "languageVersion": "3.3"
    },
    {
      "name": "source_maps",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/source_maps-0.10.13",
      "packageUri": "lib/",
      "languageVersion": "3.3"
    },
    {
      "name": "source_span",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/source_span-1.10.1",
      "packageUri": "lib/",
      "languageVersion": "3.1"
    },
    {
      "name": "stack_trace",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/stack_trace-1.12.1",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "stream_channel",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/stream_channel-2.1.4",
      "packageUri": "lib/",
      "languageVersion": "3.3"
    },
    {
      "name": "stream_transform",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/stream_transform-2.1.1",
      "packageUri": "lib/",
      "languageVersion": "3.1"
    },
    {
      "name": "string_scanner",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/string_scanner-1.4.1",
      "packageUri": "lib/",
      "languageVersion": "3.1"
    },
    {
      "name": "term_glyph",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/term_glyph-1.2.2",
      "packageUri": "lib/",
      "languageVersion": "3.1"
    },
    {
      "name": "test",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/test-1.26.2",
      "packageUri": "lib/",
      "languageVersion": "3.5"
    },
    {
      "name": "test_api",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/test_api-0.7.6",
      "packageUri": "lib/",
      "languageVersion": "3.5"
    },
    {
      "name": "test_core",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/test_core-0.6.11",
      "packageUri": "lib/",
      "languageVersion": "3.5"
    },
    {
      "name": "typed_data",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/typed_data-1.4.0",
      "packageUri": "lib/",
      "languageVersion": "3.5"
    },
    {
      "name": "vector_math",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/vector_math-2.2.0",
      "packageUri": "lib/",
      "languageVersion": "3.1"
    },
    {
      "name": "very_good_analysis",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/very_good_analysis-5.1.0",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "vm_service",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/vm_service-15.0.0",
      "packageUri": "lib/",
      "languageVersion": "3.3"
    },
    {
      "name": "watcher",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/watcher-1.1.2",
      "packageUri": "lib/",
      "languageVersion": "3.1"
    },
    {
      "name": "web",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/web-1.1.1",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "web_socket",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/web_socket-1.0.1",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "web_socket_channel",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/web_socket_channel-3.0.3",
      "packageUri": "lib/",
      "languageVersion": "3.3"
    },
    {
      "name": "webkit_inspection_protocol",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/webkit_inspection_protocol-1.2.1",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "yaml",
      "rootUri": "file:///Users/felix/.pub-cache/hosted/pub.dev/yaml-3.1.3",
      "packageUri": "lib/",
      "languageVersion": "3.4"
    },
    {
      "name": "_",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "3.6"
    },
    {
      "name": "client",
      "rootUri": "../packages/client",
      "packageUri": "lib/",
      "languageVersion": "3.8"
    },
    {
      "name": "protocol",
      "rootUri": "../packages/protocol",
      "packageUri": "lib/",
      "languageVersion": "3.8"
    },
    {
      "name": "models",
      "rootUri": "../packages/models",
      "packageUri": "lib/",
      "languageVersion": "3.8"
    },
    {
      "name": "server",
      "rootUri": "../packages/server",
      "packageUri": "lib/",
      "languageVersion": "3.6"
    }
  ],
  "generator": "pub",
  "generatorVersion": "3.9.2",
  "flutterRoot": "file:///Users/felix/Development/github.com/flutter/flutter",
  "flutterVersion": "3.35.3",
  "pubCache": "file:///Users/felix/.pub-cache"
}
''';

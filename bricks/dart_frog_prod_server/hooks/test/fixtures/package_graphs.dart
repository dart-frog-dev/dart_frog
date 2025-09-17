const packageGraphWithDirectAndTransitiveDeps = '''
{
  "roots": [
    "_",
    "client",
    "models",
    "protocol",
    "server"
  ],
  "packages": [
    {
      "name": "_",
      "version": "0.0.0",
      "dependencies": [],
      "devDependencies": []
    },
    {
      "name": "client",
      "version": "1.0.0+1",
      "dependencies": [
        "cupertino_icons",
        "flutter"
      ],
      "devDependencies": [
        "flutter_lints",
        "flutter_test"
      ]
    },
    {
      "name": "protocol",
      "version": "1.0.0",
      "dependencies": [
        "models"
      ],
      "devDependencies": [
        "lints",
        "test"
      ]
    },
    {
      "name": "models",
      "version": "1.0.0",
      "dependencies": [],
      "devDependencies": [
        "lints",
        "test"
      ]
    },
    {
      "name": "server",
      "version": "1.0.0+1",
      "dependencies": [
        "dart_frog",
        "protocol"
      ],
      "devDependencies": [
        "mocktail",
        "test",
        "very_good_analysis"
      ]
    },
    {
      "name": "very_good_analysis",
      "version": "5.1.0",
      "dependencies": []
    },
    {
      "name": "test",
      "version": "1.26.2",
      "dependencies": [
        "analyzer",
        "async",
        "boolean_selector",
        "collection",
        "coverage",
        "http_multi_server",
        "io",
        "js",
        "matcher",
        "node_preamble",
        "package_config",
        "path",
        "pool",
        "shelf",
        "shelf_packages_handler",
        "shelf_static",
        "shelf_web_socket",
        "source_span",
        "stack_trace",
        "stream_channel",
        "test_api",
        "test_core",
        "typed_data",
        "web_socket_channel",
        "webkit_inspection_protocol",
        "yaml"
      ]
    },
    {
      "name": "mocktail",
      "version": "1.0.4",
      "dependencies": [
        "collection",
        "matcher",
        "test_api"
      ]
    },
    {
      "name": "dart_frog",
      "version": "1.2.3",
      "dependencies": [
        "http_methods",
        "http_parser",
        "meta",
        "mime",
        "shelf",
        "shelf_hotreload",
        "shelf_static"
      ]
    },
    {
      "name": "lints",
      "version": "5.1.1",
      "dependencies": []
    },
    {
      "name": "flutter_lints",
      "version": "5.0.0",
      "dependencies": [
        "lints"
      ]
    },
    {
      "name": "flutter_test",
      "version": "0.0.0",
      "dependencies": [
        "clock",
        "collection",
        "fake_async",
        "flutter",
        "leak_tracker_flutter_testing",
        "matcher",
        "meta",
        "path",
        "stack_trace",
        "stream_channel",
        "test_api",
        "vector_math"
      ]
    },
    {
      "name": "cupertino_icons",
      "version": "1.0.8",
      "dependencies": []
    },
    {
      "name": "flutter",
      "version": "0.0.0",
      "dependencies": [
        "characters",
        "collection",
        "material_color_utilities",
        "meta",
        "sky_engine",
        "vector_math"
      ]
    },
    {
      "name": "yaml",
      "version": "3.1.3",
      "dependencies": [
        "collection",
        "source_span",
        "string_scanner"
      ]
    },
    {
      "name": "webkit_inspection_protocol",
      "version": "1.2.1",
      "dependencies": [
        "logging"
      ]
    },
    {
      "name": "web_socket_channel",
      "version": "3.0.3",
      "dependencies": [
        "async",
        "crypto",
        "stream_channel",
        "web",
        "web_socket"
      ]
    },
    {
      "name": "typed_data",
      "version": "1.4.0",
      "dependencies": [
        "collection"
      ]
    },
    {
      "name": "test_core",
      "version": "0.6.11",
      "dependencies": [
        "analyzer",
        "args",
        "async",
        "boolean_selector",
        "collection",
        "coverage",
        "frontend_server_client",
        "glob",
        "io",
        "meta",
        "package_config",
        "path",
        "pool",
        "source_map_stack_trace",
        "source_maps",
        "source_span",
        "stack_trace",
        "stream_channel",
        "test_api",
        "vm_service",
        "yaml"
      ]
    },
    {
      "name": "test_api",
      "version": "0.7.6",
      "dependencies": [
        "async",
        "boolean_selector",
        "collection",
        "meta",
        "source_span",
        "stack_trace",
        "stream_channel",
        "string_scanner",
        "term_glyph"
      ]
    },
    {
      "name": "stream_channel",
      "version": "2.1.4",
      "dependencies": [
        "async"
      ]
    },
    {
      "name": "stack_trace",
      "version": "1.12.1",
      "dependencies": [
        "path"
      ]
    },
    {
      "name": "source_span",
      "version": "1.10.1",
      "dependencies": [
        "collection",
        "path",
        "term_glyph"
      ]
    },
    {
      "name": "shelf_web_socket",
      "version": "3.0.0",
      "dependencies": [
        "shelf",
        "stream_channel",
        "web_socket_channel"
      ]
    },
    {
      "name": "shelf_static",
      "version": "1.1.3",
      "dependencies": [
        "convert",
        "http_parser",
        "mime",
        "path",
        "shelf"
      ]
    },
    {
      "name": "shelf_packages_handler",
      "version": "3.0.2",
      "dependencies": [
        "path",
        "shelf",
        "shelf_static"
      ]
    },
    {
      "name": "shelf",
      "version": "1.4.2",
      "dependencies": [
        "async",
        "collection",
        "http_parser",
        "path",
        "stack_trace",
        "stream_channel"
      ]
    },
    {
      "name": "pool",
      "version": "1.5.1",
      "dependencies": [
        "async",
        "stack_trace"
      ]
    },
    {
      "name": "path",
      "version": "1.9.1",
      "dependencies": []
    },
    {
      "name": "package_config",
      "version": "2.2.0",
      "dependencies": [
        "path"
      ]
    },
    {
      "name": "node_preamble",
      "version": "2.0.2",
      "dependencies": []
    },
    {
      "name": "matcher",
      "version": "0.12.17",
      "dependencies": [
        "async",
        "meta",
        "stack_trace",
        "term_glyph",
        "test_api"
      ]
    },
    {
      "name": "js",
      "version": "0.7.2",
      "dependencies": []
    },
    {
      "name": "io",
      "version": "1.0.5",
      "dependencies": [
        "meta",
        "path",
        "string_scanner"
      ]
    },
    {
      "name": "http_multi_server",
      "version": "3.2.2",
      "dependencies": [
        "async"
      ]
    },
    {
      "name": "coverage",
      "version": "1.15.0",
      "dependencies": [
        "args",
        "cli_config",
        "glob",
        "logging",
        "meta",
        "package_config",
        "path",
        "source_maps",
        "stack_trace",
        "vm_service",
        "yaml"
      ]
    },
    {
      "name": "collection",
      "version": "1.19.1",
      "dependencies": []
    },
    {
      "name": "boolean_selector",
      "version": "2.1.2",
      "dependencies": [
        "source_span",
        "string_scanner"
      ]
    },
    {
      "name": "async",
      "version": "2.13.0",
      "dependencies": [
        "collection",
        "meta"
      ]
    },
    {
      "name": "analyzer",
      "version": "7.7.1",
      "dependencies": [
        "_fe_analyzer_shared",
        "collection",
        "convert",
        "crypto",
        "glob",
        "meta",
        "package_config",
        "path",
        "pub_semver",
        "source_span",
        "watcher",
        "yaml"
      ]
    },
    {
      "name": "shelf_hotreload",
      "version": "1.5.0",
      "dependencies": [
        "hotreloader",
        "logging"
      ]
    },
    {
      "name": "mime",
      "version": "2.0.0",
      "dependencies": []
    },
    {
      "name": "meta",
      "version": "1.16.0",
      "dependencies": []
    },
    {
      "name": "http_parser",
      "version": "4.1.2",
      "dependencies": [
        "collection",
        "source_span",
        "string_scanner",
        "typed_data"
      ]
    },
    {
      "name": "http_methods",
      "version": "1.1.1",
      "dependencies": []
    },
    {
      "name": "leak_tracker_flutter_testing",
      "version": "3.0.10",
      "dependencies": [
        "flutter",
        "leak_tracker",
        "leak_tracker_testing",
        "matcher",
        "meta"
      ]
    },
    {
      "name": "vector_math",
      "version": "2.2.0",
      "dependencies": []
    },
    {
      "name": "clock",
      "version": "1.1.2",
      "dependencies": []
    },
    {
      "name": "fake_async",
      "version": "1.3.3",
      "dependencies": [
        "clock",
        "collection"
      ]
    },
    {
      "name": "sky_engine",
      "version": "0.0.0",
      "dependencies": []
    },
    {
      "name": "material_color_utilities",
      "version": "0.11.1",
      "dependencies": [
        "collection"
      ]
    },
    {
      "name": "characters",
      "version": "1.4.0",
      "dependencies": []
    },
    {
      "name": "string_scanner",
      "version": "1.4.1",
      "dependencies": [
        "source_span"
      ]
    },
    {
      "name": "logging",
      "version": "1.3.0",
      "dependencies": []
    },
    {
      "name": "web_socket",
      "version": "1.0.1",
      "dependencies": [
        "web"
      ]
    },
    {
      "name": "web",
      "version": "1.1.1",
      "dependencies": []
    },
    {
      "name": "crypto",
      "version": "3.0.6",
      "dependencies": [
        "typed_data"
      ]
    },
    {
      "name": "vm_service",
      "version": "15.0.0",
      "dependencies": []
    },
    {
      "name": "source_maps",
      "version": "0.10.13",
      "dependencies": [
        "source_span"
      ]
    },
    {
      "name": "source_map_stack_trace",
      "version": "2.1.2",
      "dependencies": [
        "path",
        "source_maps",
        "stack_trace"
      ]
    },
    {
      "name": "glob",
      "version": "2.1.3",
      "dependencies": [
        "async",
        "collection",
        "file",
        "path",
        "string_scanner"
      ]
    },
    {
      "name": "frontend_server_client",
      "version": "4.0.0",
      "dependencies": [
        "async",
        "path"
      ]
    },
    {
      "name": "args",
      "version": "2.7.0",
      "dependencies": []
    },
    {
      "name": "term_glyph",
      "version": "1.2.2",
      "dependencies": []
    },
    {
      "name": "convert",
      "version": "3.1.2",
      "dependencies": [
        "typed_data"
      ]
    },
    {
      "name": "cli_config",
      "version": "0.2.0",
      "dependencies": [
        "args",
        "yaml"
      ]
    },
    {
      "name": "watcher",
      "version": "1.1.2",
      "dependencies": [
        "async",
        "path"
      ]
    },
    {
      "name": "pub_semver",
      "version": "2.2.0",
      "dependencies": [
        "collection"
      ]
    },
    {
      "name": "_fe_analyzer_shared",
      "version": "85.0.0",
      "dependencies": [
        "meta"
      ]
    },
    {
      "name": "hotreloader",
      "version": "4.3.0",
      "dependencies": [
        "collection",
        "logging",
        "path",
        "stream_transform",
        "vm_service",
        "watcher"
      ]
    },
    {
      "name": "leak_tracker_testing",
      "version": "3.0.2",
      "dependencies": [
        "leak_tracker",
        "matcher",
        "meta"
      ]
    },
    {
      "name": "leak_tracker",
      "version": "11.0.1",
      "dependencies": [
        "clock",
        "collection",
        "meta",
        "path",
        "vm_service"
      ]
    },
    {
      "name": "file",
      "version": "7.0.1",
      "dependencies": [
        "meta",
        "path"
      ]
    },
    {
      "name": "stream_transform",
      "version": "2.1.1",
      "dependencies": []
    }
  ],
  "configVersion": 1
}
''';

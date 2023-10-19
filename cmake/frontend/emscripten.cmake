function(nui_prepare_emscripten_target)
    cmake_parse_arguments(
        NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS
        "NO_INLINE;NO_INLINE_INJECT"
        "TARGET;PREJS;STATIC;UNPACKED_MODE"
        "EMSCRIPTEN_LINK_OPTIONS;EMSCRIPTEN_COMPILE_OPTIONS;PARCEL_ARGS"
        ${ARGN}
    )

    if (NOT NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_STATIC)
        get_target_property(NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_SOURCE_DIR ${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET} SOURCE_DIR)
        set(NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_STATIC "${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_SOURCE_DIR}/static")
    endif()

    nui_set_target_output_directories(${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET})

    if (NOT NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_UNPACKED_MODE)
        set(NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_UNPACKED_MODE off)
    endif()

    set(INLINER_COMMAND "")
    if (NOT NO_INLINE)
        nui_enable_inline(TARGET ${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET})
        if (NOT NO_INLINE_INJECT)
            set(INLINER_COMMAND COMMAND ${NUI_INLINE_INJECTOR_TARGET_FILE} "${CMAKE_BINARY_DIR}/static/index.html" "${CMAKE_BINARY_DIR}/nui-inline/inline_imports.js" "${CMAKE_BINARY_DIR}/nui-inline/inline_imports.css")
        endif()
    endif()

    add_custom_target(
        ${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET}-npm-install
        COMMAND npm install
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )

    add_custom_target(
        ${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET}-parcel
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${NUI_SOURCE_DIRECTORY}/nui/js" "${CMAKE_BINARY_DIR}/nui-js"
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_STATIC} "${CMAKE_BINARY_DIR}/static"
        ${INLINER_COMMAND}
        COMMAND "${CMAKE_BINARY_DIR}/node_modules/.bin/parcel" build --dist-dir "${CMAKE_BINARY_DIR}/bin" ${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_PARCEL_ARGS}
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        BYPRODUCTS "${CMAKE_BINARY_DIR}/bin/index.html"
        DEPENDS "${CMAKE_BINARY_DIR}/bin/index.js"
    )

    if (${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_UNPACKED_MODE})
        set(SINGLE_FILE_STRING "")
        add_custom_target(
            ${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET}-copy-wasm
            COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_BINARY_DIR}/bin/index.wasm" "${CMAKE_BINARY_DIR}/../bin/index.wasm"
        )
        add_dependencies(${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET}-parcel ${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET}-copy-wasm)
    else()
        set(SINGLE_FILE_STRING "-sSINGLE_FILE")
    endif()

    string (REPLACE ";" " " EMSCRIPTEN_LINK "${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_EMSCRIPTEN_LINK_OPTIONS}")
    string (REPLACE ";" " " EMSCRIPTEN_COMPILE "${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_EMSCRIPTEN_COMPILE_OPTIONS}")
    set_target_properties(
        ${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET}
        PROPERTIES
            LINK_FLAGS
                "-sENVIRONMENT=web ${SINGLE_FILE_STRING} -sNO_EXIT_RUNTIME=1 ${EMSCRIPTEN_LINK} -lembind --pre-js=\"${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_PREJS}\""
            COMPILE_FLAGS
                "${EMSCRIPTEN_COMPILE}"
    )
    set_target_properties(${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET} PROPERTIES OUTPUT_NAME "index")
    add_dependencies(${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET}-parcel ${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET}-npm-install)
    add_dependencies(${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET}-parcel ${NUI_PREPARE_EMSCRIPTEN_TARGET_ARGS_TARGET})
endfunction()

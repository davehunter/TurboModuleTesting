add_library(glog_stub STATIC glog_stub.cpp)

add_library(TurboModuleTesting STATIC)
target_sources(TurboModuleTesting PUBLIC
    TurboModuleTesting.h
    TurboModuleTestingEnvironment.h
    TurboModuleTestingEnvironment.cpp
)
target_include_directories(TurboModuleTesting PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}"
)

#include <ostream>
#include <sstream>

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
// Stub implementation of glog's LogMessage for testing purposes
//
// Note, the CMake for glog has been stripped out of the glog cocoapod,
// so this file is used instead when building TurboModuleTesting targets.
//
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

namespace google {

class LogMessage {
public:
    LogMessage(const char*, int, int);
    ~LogMessage();

    std::ostream& stream();
};

LogMessage::LogMessage(const char*, int, int) { }
LogMessage::~LogMessage() = default;

std::ostream& LogMessage::stream()
{
    static std::ostringstream sink;
    return sink;
}

void FlushLogFiles(int) { }

} // namespace google

#include <algorithm>
#include <cerrno>
#include <csignal>
#include <cstdio>
#include <cstring>
#include <dirent.h>
#include <fcntl.h>
#include <linux/input.h>
#include <poll.h>
#include <string>
#include <sys/ioctl.h>
#include <unistd.h>
#include <vector>

namespace {

constexpr int kBitsPerLong = static_cast<int>(sizeof(unsigned long) * 8);

int bitArraySize(int maxBit) {
    return (maxBit / kBitsPerLong) + 1;
}

bool isBitSet(const std::vector<unsigned long>& bits, int bit) {
    const int index = bit / kBitsPerLong;
    if (index < 0 || index >= static_cast<int>(bits.size())) {
        return false;
    }
    return (bits[index] & (1UL << (bit % kBitsPerLong))) != 0;
}

bool readBits(int fd, unsigned long request, std::vector<unsigned long>* bits) {
    std::fill(bits->begin(), bits->end(), 0);
    return ioctl(fd, request, bits->data()) >= 0;
}

bool getDeviceName(int fd, std::string* name) {
    char buffer[256] = {};
    if (ioctl(fd, EVIOCGNAME(sizeof(buffer)), buffer) < 0) {
        return false;
    }
    *name = buffer;
    return true;
}

bool isTouchscreen(int fd) {
    std::vector<unsigned long> evBits(bitArraySize(EV_MAX));
    if (!readBits(fd, EVIOCGBIT(0, evBits.size() * sizeof(unsigned long)), &evBits)) {
        return false;
    }
    if (!isBitSet(evBits, EV_ABS)) {
        return false;
    }

    std::vector<unsigned long> absBits(bitArraySize(ABS_MAX));
    if (!readBits(fd, EVIOCGBIT(EV_ABS, absBits.size() * sizeof(unsigned long)), &absBits)) {
        return false;
    }

    const bool hasMtPosition =
            isBitSet(absBits, ABS_MT_POSITION_X) && isBitSet(absBits, ABS_MT_POSITION_Y);
    const bool hasSingleTouchPosition = isBitSet(absBits, ABS_X) && isBitSet(absBits, ABS_Y);
    if (!hasMtPosition && !hasSingleTouchPosition) {
        return false;
    }

    std::vector<unsigned long> propBits(bitArraySize(INPUT_PROP_MAX));
    const bool hasProps =
            readBits(fd, EVIOCGPROP(propBits.size() * sizeof(unsigned long)), &propBits);
    if (!hasProps) {
        return hasMtPosition;
    }

    const bool isDirect = isBitSet(propBits, INPUT_PROP_DIRECT);
    const bool isPointer = isBitSet(propBits, INPUT_PROP_POINTER);
    return isDirect || (hasMtPosition && !isPointer);
}

std::vector<std::string> listEventNodes() {
    std::vector<std::string> paths;
    DIR* dir = opendir("/dev/input");
    if (dir == nullptr) {
        return paths;
    }

    while (dirent* entry = readdir(dir)) {
        if (std::strncmp(entry->d_name, "event", 5) != 0) {
            continue;
        }
        paths.emplace_back(std::string("/dev/input/") + entry->d_name);
    }
    closedir(dir);
    std::sort(paths.begin(), paths.end());
    return paths;
}

volatile sig_atomic_t keepRunning = 1;

void handleSignal(int) {
    keepRunning = 0;
}

}  // namespace

int main() {
    std::signal(SIGINT, handleSignal);
    std::signal(SIGTERM, handleSignal);

    std::vector<int> grabbedFds;
    for (const std::string& path : listEventNodes()) {
        int fd = open(path.c_str(), O_RDONLY | O_NONBLOCK | O_CLOEXEC);
        if (fd < 0) {
            continue;
        }

        if (!isTouchscreen(fd)) {
            close(fd);
            continue;
        }

        int grab = 1;
        if (ioctl(fd, EVIOCGRAB, &grab) < 0) {
            std::fprintf(stderr, "Failed to grab %s: %s\n", path.c_str(), std::strerror(errno));
            close(fd);
            continue;
        }

        std::string name;
        getDeviceName(fd, &name);
        std::printf("Grabbed touchscreen %s (%s)\n", path.c_str(), name.c_str());
        grabbedFds.push_back(fd);
    }

    if (grabbedFds.empty()) {
        std::fprintf(stderr, "No touchscreen input devices found\n");
        return 1;
    }

    std::vector<pollfd> pollFds;
    pollFds.reserve(grabbedFds.size());
    for (int fd : grabbedFds) {
        pollFds.push_back({fd, POLLIN, 0});
    }

    input_event event;
    while (keepRunning) {
        int ret = poll(pollFds.data(), pollFds.size(), -1);
        if (ret < 0) {
            if (errno == EINTR) {
                continue;
            }
            break;
        }

        for (pollfd& pollFd : pollFds) {
            if ((pollFd.revents & POLLIN) == 0) {
                continue;
            }
            while (read(pollFd.fd, &event, sizeof(event)) == sizeof(event)) {
            }
        }
    }

    for (int fd : grabbedFds) {
        int grab = 0;
        ioctl(fd, EVIOCGRAB, &grab);
        close(fd);
    }
    return 0;
}
